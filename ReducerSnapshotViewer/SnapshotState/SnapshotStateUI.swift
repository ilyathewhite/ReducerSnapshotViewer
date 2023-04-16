//
//  SnapshotStateUI.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/8/23.
//

import Foundation

import SwiftUI
import SwiftUIEx
import FoundationEx
import ReducerArchitecture

extension SnapshotState: StoreUINamespace {
    struct ContentView: StoreContentView {
        @Environment(\.codingFont) var codingFont
        
        typealias Nsp = SnapshotState
        @ObservedObject var store: Store
        
        @State private var fixedWidth: CGFloat?
        private let propertyNamePadding: CGFloat = 10
        
        @State private var stringDiffUI: StoreUI<StringDiff>?

        @ViewBuilder
        func stringDiffView() -> some View {
            NavigationStack {
                stringDiffUI?.makeView()
                    .navigationTitle(stringDiffUI?.store.state.title ?? "Diff")
                    .toolbar {
                        ToolbarItemGroup(placement: .confirmationAction) {
                            Button("Done") {
                                stringDiffUI = nil
                            }
                        }
                    }
            }
        }

        init(store: Store) {
            self.store = store
        }
        
        var body: some View {
            ScrollView {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 20, verticalSpacing: 5) {
                    ForEach(store.state.rows) { row in
                        GridRow {
                            HStack(spacing: 0) {
                                Spacer()
                                    .frame(width: 15)
                                
                                Circle()
                                    .fill(row.isUpdated ? .blue : .clear)
                                    .frame(width: 15, height: 15)
                                    .frame(alignment: .center)
                                
                                Button(action: {
                                    let action: Store.MutatingAction = .toggleExpanded(property: row.property)
                                    store.send(.mutating(action, animated: true, .easeInOut(duration: 0.2)))
                                }) {
                                    Image(systemName: "chevron.forward")
                                        .rotationEffect(.degrees(row.isExpanded ? 90 : 0))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, height: 40)
                                }
                                
                                Text(row.property)
                                    .textSelection(.enabled)
                                    .padding(.vertical, propertyNamePadding)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(codingFont)
                                    .foregroundColor(.secondary)
                                    .fitCodeString(charCount: 25, fixedWidth: true)
                            }
                            .measurement(FixedWidthKey.self) { proxy in
                                proxy.size.width
                            }
                            .onPreferenceChange(FixedWidthKey.self) {
                                fixedWidth = $0
                            }
                            .frame(width: fixedWidth)

                            Text(row.value.latest)
                                .textSelection(.enabled)
                                .padding(.vertical, propertyNamePadding)
                                .lineLimit(row.isExpanded ? nil : 1)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(codingFont)
                                .fitCodeString(fixedWidth: false)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard let (old, new) = row.change else { return }
                            store.send(.effect(.showDiff(propertyName: row.property, oldValue: old, newValue: new)))
                        }
                        .sheet(isPresented: showUI(\.stringDiffUI)) {
                            stringDiffView()
                        }
                        Divider()
                    }
                }
                .buttonStyle(.borderless)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .connectOnAppear {
                store.environment = .init(
                    showDiff: { property, oldValue, newValue in
                        let store = StringDiff.store(
                            title: property,
                            string1Caption: "Old Value",
                            string1: oldValue,
                            string2Caption: "New Value",
                            string2: newValue
                        )
                        stringDiffUI = .init(store)
                    }
                )
            }
        }
    }
}

struct SnapshotState_Previews: PreviewProvider {
    static let state: [CodePropertyValuePair] = [
        .init(property: "intValue", value: "123"),
        .init(
            property: "stringValue",
            value: """
            StoreState(
               chord: CustomGuitarChord(
                  name: "",
                  notesByPitch: [
                     GuitarChordNote(
                        pitch: F♯4,
                        fret: 2,
                        string: 5,
                        scaleNote: F♯,
                        scaleDegree: nil
                     )
                  ],
                  guitar: Guitar(
                     tuning: Tuning(
                        name: "Standard",
                        strings: [E2, A2, D3, G3, B3, E4]
                     ),
                     fretCount: 12,
                     capoFret: 0,
                     maxNumberOfFretsInChord: 4
                  ),
                  chordSymbol: "",
                  fingeringInfo: ChordFingeringInfo(
                     fingering: [. , . , . , . , . , .2],
                     minDiffFromMaxStretch: 5,
                     barreString: nil,
                     barreFret: nil,
                     barreNoteCount: nil
                  ),
                  diagramInfo: ChordDiagramInfo(
                     capoFret: 0,
                     firstFretAboveCapo: 2,
                     startFret: 2,
                     diagramStartFret: 0,
                     endFret: 3,
                     startString: 5,
                     endString: 6,
                     barreString: nil,
                     barreFret: nil,
                     barreNoteCount: nil
                  )
               ),
               play: (GuitarChord) -> ()(),
               matchingChordSpecs: [],
               isPickingElement: false,
               actionRect: nil,
               isPickingRootNote: false,
               isPickingBarreNote: false,
               pickingNoteMessage: nil
            )
            """
        ),
        .init(property: "doubleValue", value: "3.14159"),
        .init(property: "rediculouslyLongPropertyNameForTesting", value: "3.14159")
    ]

    static let state2: [CodePropertyValuePair] = [
        .init(property: "intValue", value: "123"),
        .init(property: "stringValue", value: "Hello"),
        .init(property: "doubleValue", value: "3.14159"),
        .init(property: "rediculouslyLongPropertyNameForTesting", value: "3.14159")
    ]

    static let store = SnapshotState.store(state: state)
    
    static var previews: some View {
        VStack {
            SnapshotState.ContentView(store: store)
                .frame(width: 900)
            Button("Update") {
                store.send(.mutating(.update(state2, from: state), animated: true, .easeInOut(duration: 0.2)))
            }
            .padding()
            .buttonStyle(.borderless)
        }
    }
}
