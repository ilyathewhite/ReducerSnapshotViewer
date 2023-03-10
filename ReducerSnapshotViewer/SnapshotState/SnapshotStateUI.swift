//
//  SnapshotStateUI.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/8/23.
//

import Foundation

import SwiftUI
import FoundationEx
import ReducerArchitecture

extension SnapshotState: StoreUIWrapper {
    struct ContentView: StoreContentView {
        @Environment(\.codingFont) var codingFont
        
        typealias StoreWrapper = SnapshotState
        @ObservedObject var store: Store
        
        init(store: Store) {
            self.store = store
        }
        
        var body: some View {
            ScrollView {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 20, verticalSpacing: 5) {
                    ForEach(store.state.rows) { row in
                        GridRow {
                            HStack(spacing: 0) {
                                Circle()
                                    .fill(row.isUpdated ? .blue : .clear)
                                    .frame(width: 20, height: 20)
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
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(codingFont)
                                    .foregroundColor(.secondary)
                                    .fitCodeString(charCount: 25)
                            }
                            
                            Text(row.value)
                                .lineLimit(row.isExpanded ? nil : 1)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(codingFont)
                                .fitCodeString()
                        }
                        Divider()
                            .gridCellUnsizedAxes(.horizontal)
                    }
                }
                .buttonStyle(.borderless)
                .frame(maxHeight: .infinity, alignment: .top)
                // .border(.gray)
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
            Button("Update") {
                store.send(.mutating(.update(state2, resetUpdateStatus: false), animated: true, .easeInOut(duration: 0.2)))
            }
            .buttonStyle(.borderless)
        }
    }
}
