//
//  SnapshotCollectionViewerUI.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/8/23.
//

import Foundation

import SwiftUI
import SwiftUIEx
import ReducerArchitecture

enum FixedWidthTag {}
typealias FixedWidthKey = FirstMeasurementKey<CGFloat, FixedWidthTag>

extension SnapshotCollectionViewer: StoreUIWrapper {
    struct ContentView: StoreContentView {
        typealias StoreWrapper = SnapshotCollectionViewer
        @ObservedObject var store: Store
        
        init(store: Store) {
            self.store = store
        }
        
        @Environment(\.colorScheme) var colorScheme
        var backgroundColor: Color {
            switch colorScheme {
            case .dark:
                return .black
            default:
                return .white
            }
        }
        
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
        
        @State private var actionViewFixedWidth: CGFloat?
        @State private var snapshotStateViewFixedWidth: CGFloat?
        
        func widths(total w: CGFloat) -> (actionViewWidth: CGFloat?, snapshotStateViewWidth: CGFloat?) {
            guard let d1 = actionViewFixedWidth else { return (nil, nil) }
            guard let d2 = snapshotStateViewFixedWidth else { return (nil, nil) }
            let x = floor((w - (d1 + d2)) / 2)
            let w1 = x + d1
            let w2 = w - w1
            return (w1, w2)
        }

        @ViewBuilder
        var toolbar: some View {
            HStack {
                Button(action: { store.send(.mutating(.moveToFirst, animated: true, stepAnimation)) }) {
                    Image(systemName: "arrow.left.to.line.circle")
                }
                .keyboardShortcut(.leftArrow, modifiers: .command)
                .disabled(store.state.isAtStart)

                Button(action: { store.send(.mutating(.moveBackward, animated: true, stepAnimation)) }) {
                    Image(systemName: "arrow.left.circle")
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
                .disabled(store.state.isAtStart)

                Button(action: { store.send(.mutating(.moveForward, animated: true, stepAnimation)) }) {
                    Image(systemName: "arrow.right.circle")
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .disabled(store.state.isAtEnd)
                
                Button(action: { store.send(.mutating(.moveToLast, animated: true, stepAnimation)) }) {
                    Image(systemName: "arrow.right.to.line.circle")
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)
                .disabled(store.state.isAtEnd)
            }
            .padding(10)
            .font(.system(size: 50))
        }
        
        var body: some View {
            VStack(spacing: 0) {
                ProgressView(value: store.state.progressValue)
                    .progressViewStyle(.linear)
                    .offset(x: 0, y: -5) // hide extra padding

                Text(store.state.snapshotCollection.title)
                    .font(.title)
                    .padding()

                Divider()
                
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        let (actionViewWidth, snapshotStateViewWidth) = widths(total: proxy.size.width)
                        actionView
                            .onPreferenceChange(FixedWidthKey.self) {
                                actionViewFixedWidth = $0
                            }
                            .frame(width: actionViewWidth)
                        
                        Divider()
                        
                        SnapshotState.ContentView(store: snapshotStateStore)
                            .onPreferenceChange(FixedWidthKey.self) {
                                snapshotStateViewFixedWidth = $0
                            }
                            .frame(width: snapshotStateViewWidth)
                    }
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
            .background(backgroundColor)
            .frame(minWidth: 1440, minHeight: 900)
        }
    }
}

struct SnapshotPlayer_Previews: PreviewProvider {
    static let snapshotCollection: ReducerSnapshotCollection = {
        let data = try! Data(contentsOf: Bundle.main.url(forResource: "ChordDiagramEditor", withExtension: "json")!)
        return try! JSONDecoder().decode(ReducerSnapshotCollection.self, from: data)
    }()
    
    static let store = SnapshotCollectionViewer.store(snapshotCollection: snapshotCollection)
    
    static var previews: some View {
        SnapshotCollectionViewer.ContentView(store: store)
    }
}
