//
//  SnapshotPlayer.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/8/23.
//

import Foundation
import FoundationEx
import ReducerArchitecture

enum SnapshotPlayer: StoreNamespace {
    typealias PublishedValue = Void
    
    struct StoreEnvironment {
        let updateSnapshot: ([CodePropertyValuePair], _ resetUpdateStatus: Bool) -> Void
    }
    
    enum MutatingAction {
        case moveForward
        case moveBackward
        case moveToFirst
        case moveToLast
    }
    
    enum EffectAction {
        case updateSnapshot([CodePropertyValuePair], resetUpdateStatus: Bool)
    }
    
    struct Iterator: Equatable {
        enum SnapshotStep {
            case input, stateChange, output
        }
        
        var snapshotStep: SnapshotStep = .input
        var index = 0
    }
    
    struct StoreState {
        let snapshots: [ReducerSnapshotData]
        var iterator: Iterator = .init()
        
        var inputAction: String? {
            let snapshot = snapshots[iterator.index]
            switch iterator.snapshotStep {
            case .input:
                return snapshot.action
            case .stateChange:
                return nil
            case .output:
                return nil
            }
        }
        
        var outputAction: String? {
            let snapshot = snapshots[iterator.index]
            switch iterator.snapshotStep {
            case .input:
                return nil
            case .stateChange:
                return nil
            case .output:
                return snapshot.effect
            }
        }
        
        var snapshotState: [CodePropertyValuePair] {
            let snapshot = snapshots[iterator.index]
            switch iterator.snapshotStep {
            case .input:
                return snapshot.inputState
            case .stateChange:
                return snapshot.outputState
            case .output:
                return snapshot.outputState
            }
        }
        
        var isAtEnd: Bool {
            if iterator.index == snapshots.count {
                return true
            }
            else if iterator.index + 1 == snapshots.count {
                switch iterator.snapshotStep {
                case .input:
                    return false
                case .stateChange:
                    return false
                case .output:
                    return true
                }
            }
            else {
                return false
            }
        }
        
        var isAtStart: Bool {
            if iterator.index > 0 {
                return false
            }
            else {
                switch iterator.snapshotStep {
                case .output:
                    return false
                case .stateChange:
                    return false
                case .input:
                    return true
                }
            }
        }
    }
}

extension SnapshotPlayer {
    @MainActor
    static func store(snapshots: [ReducerSnapshotData]) -> Store {
        Store(identifier, .init(snapshots: snapshots), reducer: reducer(), env: nil)
    }
    
    @MainActor
    static func reducer() -> Reducer {
        .init(
            run: { state, action in
                switch action {
                case .moveForward:
                    guard !state.isAtEnd else { return .none }
                    switch state.iterator.snapshotStep {
                    case .input:
                        state.iterator.snapshotStep = .stateChange
                    case .stateChange:
                        state.iterator.snapshotStep = .output
                    case .output:
                        state.iterator.index += 1
                        state.iterator.snapshotStep = .input
                    }
                    return .action(.effect(.updateSnapshot(state.snapshotState, resetUpdateStatus: false)))
                    
                case .moveBackward:
                    guard !state.isAtStart else { return .none }
                    switch state.iterator.snapshotStep {
                    case .output:
                        state.iterator.snapshotStep = .stateChange
                    case .stateChange:
                        state.iterator.snapshotStep = .input
                    case .input:
                        state.iterator.index -= 1
                        state.iterator.snapshotStep = .output
                    }
                    return .action(.effect(.updateSnapshot(state.snapshotState, resetUpdateStatus: false)))
                    
                case .moveToFirst:
                    state.iterator = .init()
                    return .action(.effect(.updateSnapshot(state.snapshotState, resetUpdateStatus: true)))
                    
                case .moveToLast:
                    state.iterator.index = state.snapshots.count - 1
                    state.iterator.snapshotStep = .output
                    return .action(.effect(.updateSnapshot(state.snapshotState, resetUpdateStatus: true)))
                }
            },
            effect: { env, state, action in
                switch action {
                case let .updateSnapshot(snapshot, resetUpdateStatus):
                    env.updateSnapshot(snapshot, resetUpdateStatus)
                    return .none
                }
            }
        )
    }
}
