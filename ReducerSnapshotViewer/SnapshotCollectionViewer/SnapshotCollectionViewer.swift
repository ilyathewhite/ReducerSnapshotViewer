//
//  SnapshotCollectionViewer.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/8/23.
//

import Foundation
import FoundationEx
import ReducerArchitecture

enum SnapshotCollectionViewer: StoreNamespace {
    typealias PublishedValue = Void
    
    struct StoreEnvironment {
        let updateSnapshot: ([CodePropertyValuePair], _ from: [CodePropertyValuePair]) -> Void
    }
    
    enum MutatingAction {
        case moveForward
        case moveBackward
        case moveToFirst
        case moveToLast
    }
    
    enum EffectAction {
        case updateSnapshot
    }
    
    struct StoreState {
        let snapshotCollection: ReducerSnapshotCollection
        var index: Int = 0
        
        var snapshots: [ReducerSnapshotData] {
            snapshotCollection.snapshots
        }
        
        var progressValue: Double {
            guard snapshots.count >= 0 else { return 1 }
            return Double(index + 1) / Double(snapshots.count)
        }
        
        var inputAction: String? {
            switch snapshots[index] {
            case let .input(_, action: action, encodedAction: _, state: _, encodedState: _, nestedLevel: _):
                return action
            default:
                return nil
            }
        }
        
        var outputAction: String? {
            switch snapshots[index] {
            case let .output(_, effect: effect, encodedEffect: _, state: _, encodedState: _, nestedLevel: _):
                return effect
            default:
                return nil
            }
        }
        
        func snapshotState(at index: Int) -> [CodePropertyValuePair] {
            switch snapshots[index] {
            case let .input(_, action: _, encodedAction: _, state: state, encodedState: _, nestedLevel: _):
                return state
            case let .stateChange(_, state: state, encodedState: _, nestedLevel: _):
                return state
            case let .output(_, effect: _, encodedEffect: _, state: state, encodedState: _, nestedLevel: _):
                return state
            }
        }
        
        var snapshotState: [CodePropertyValuePair] {
            snapshotState(at: index)
        }
        
        var prevSnapshotState: [CodePropertyValuePair] {
            index - 1 >= 0 ? snapshotState(at: index - 1) : snapshotState(at: index)
        }
        
        var nestedLevel: Int {
            switch snapshots[index] {
            case let .input(_, action: _, encodedAction: _, state: _, encodedState: _, nestedLevel: nestedLevel):
                return nestedLevel
            case let .stateChange(_, state: _, encodedState: _, nestedLevel: nestedLevel):
                return nestedLevel
            case let .output(_, effect: _, encodedEffect: _, state: _, encodedState: _, nestedLevel: nestedLevel):
                return nestedLevel
            }
        }
        
        var isAtEnd: Bool {
            index >= snapshots.count - 1
        }
        
        var isAtStart: Bool {
            index == 0
        }
    }
}

extension SnapshotCollectionViewer {
    @MainActor
    static func store(snapshotCollection: ReducerSnapshotCollection) -> Store {
        Store(identifier, .init(snapshotCollection: snapshotCollection), reducer: reducer(), env: nil)
    }
    
    @MainActor
    static func reducer() -> Reducer {
        .init(
            run: { state, action in
                switch action {
                case .moveForward:
                    guard !state.isAtEnd else { return .none }
                    state.index += 1
                    return .action(.effect(.updateSnapshot))
                    
                case .moveBackward:
                    guard !state.isAtStart else { return .none }
                    state.index -= 1
                    return .action(.effect(.updateSnapshot))

                case .moveToFirst:
                    state.index = 0
                    return .action(.effect(.updateSnapshot))

                case .moveToLast:
                    state.index = state.snapshots.count - 1
                    return .action(.effect(.updateSnapshot))
                }
            },
            effect: { env, state, action in
                switch action {
                case .updateSnapshot:
                    env.updateSnapshot(state.snapshotState, state.prevSnapshotState)
                    return .none
                }
            }
        )
    }
}
