//
//  SnapshotPlayerUI.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/8/23.
//

import Foundation

import SwiftUI
import SwiftUIEx
import ReducerArchitecture

extension SnapshotPlayer: StoreUIWrapper {
    struct ContentView: StoreContentView {
        typealias StoreWrapper = SnapshotPlayer
        @ObservedObject var store: Store
        
        @StateObject private var snapshotStateStore = SnapshotState.store(state: [])
        
        let stepAnimation: Animation = .easeOut(duration: 0.15)
        
        var actionView: some View {
            let action: String?
            let mode: SnapshotActionView.Mode
            if let inputAction = store.state.inputAction {
                action = inputAction
                mode = .input
            }
            else if let outputAction = store.state.outputAction {
                action = outputAction
                mode = .output
            }
            else {
                mode = .stateChange
                action = nil
            }
            return SnapshotActionView(action: action, mode: mode)
        }
        
        enum SnapshotWidthTag {}
        typealias SnapshotWidthKey = FirstMeasurementKey<CGFloat, SnapshotWidthTag>
        @State private var snapshotWidth: CGFloat?
        
        var snapshotStateView: some View {
            HStack {
                Divider()
                SnapshotState.ContentView(store: snapshotStateStore)
                Divider()
            }
        }

        @ViewBuilder
        var toolbar: some View {
            HStack {
                Button(action: { store.send(.mutating(.moveToFirst, animated: true, stepAnimation)) }) {
                    Image(systemName: "arrow.left.to.line.circle")
                }
                .disabled(store.state.isAtStart)

                Button(action: { store.send(.mutating(.moveBackward, animated: true, stepAnimation)) }) {
                    Image(systemName: "arrow.left.circle")
                }
                .disabled(store.state.isAtStart)

                Button(action: { store.send(.mutating(.moveForward, animated: true, stepAnimation)) }) {
                    Image(systemName: "arrow.right.circle")
                }
                .disabled(store.state.isAtEnd)
                
                Button(action: { store.send(.mutating(.moveToLast, animated: true, stepAnimation)) }) {
                    Image(systemName: "arrow.right.to.line.circle")
                }
                .disabled(store.state.isAtEnd)
            }
            .padding(10)
            .font(.system(size: 50))
        }
        
        var body: some View {
            VStack {
                GeometryReader { proxy in
                    Grid(horizontalSpacing: 0) {
                        GridRow {
                            actionView
                                .frame(width: snapshotWidth.map { proxy.size.width - $0 } )
                            snapshotStateView
                                .measureWidth(SnapshotWidthKey.self) {
                                    snapshotWidth = $0
                                }
                        }
                    }
                    .frame(width: proxy.size.width)
                }
                Divider()
                toolbar
            }
            .connectOnAppear {
                store.environment = .init(
                    updateSnapshot: {
                        snapshotStateStore.send(.mutating(.update($0, resetUpdateStatus: $1), animated: true, stepAnimation))
                    }
                )
                
                snapshotStateStore.send(.mutating(.update(store.state.snapshotState, resetUpdateStatus: true)))
            }
            .buttonStyle(.borderless)
        }
    }
}

struct SnapshotPlayer_Previews: PreviewProvider {
    static let snapshots: [ReducerSnapshotData] = {
        let data = try! Data(contentsOf: Bundle.main.url(forResource: "ChordDiagramEditor", withExtension: "json")!)
        return try! JSONDecoder().decode([ReducerSnapshotData].self, from: data)
    }()
    
    static let store = SnapshotPlayer.store(snapshots: snapshots)
    
    static var previews: some View {
        SnapshotPlayer.ContentView(store: store)
    }
}
