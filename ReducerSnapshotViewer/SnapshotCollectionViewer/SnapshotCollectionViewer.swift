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
        case moveForwardUser
        case moveBackwardUser
        case updateJumpStepInput(String)
        case jumpTo(step: Int)
    }
    
    enum EffectAction {
        case updateSnapshot
    }
    
    struct StoreState {
        let snapshotCollection: ReducerSnapshotCollection
        var index: Int = 0
        var jumpStepInput = ""
        
        var snapshots: [ReducerSnapshotData] {
            snapshotCollection.snapshots
        }
        
        var progressValue: Double {
            guard snapshots.count >= 0 else { return 1 }
            return Double(index + 1) / Double(snapshots.count)
        }
        
        var inputAction: String? {
            switch snapshots[index] {
            case .input(let input):
                return input.action
            default:
                return nil
            }
        }
        
        var isUserAction: Bool {
            isUserAction(at: index)
        }
        
        func isUserAction(at index: Int) -> Bool {
            switch snapshots[index] {
            case .input(let input):
                return input.action.starts(with: ".user(")
            default:
                return false
            }
        }
        
        var outputAction: String? {
            switch snapshots[index] {
            case .output(let output):
                return output.effect
            default:
                return nil
            }
        }
        
        func snapshotState(at index: Int) -> [CodePropertyValuePair] {
            switch snapshots[index] {
            case .input(let input):
                return input.state
            case .stateChange(let stateChange):
                return stateChange.state
            case .output(let output):
                return output.state
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
            case .input(let input):
                return input.nestedLevel
            case .stateChange(let stateChange):
                return stateChange.nestedLevel
            case .output(let output):
                return output.nestedLevel
            }
        }
        
        var isAtEnd: Bool {
            index >= snapshots.count - 1
        }
        
        var isAtStart: Bool {
            index == 0
        }
        
        var stepString: String {
            String(index + 1)
        }
        
        func canJumpTo(step: Int) -> Bool {
            let index = step - 1
            return (0 <= index) && (index < snapshots.count)
        }
        
        mutating func jump(to step: Int) -> Bool {
            guard canJumpTo(step: step) else { return false }
            index = step - 1
            jumpStepInput = ""
            return true
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
                    
                case .moveForwardUser:
                    var index = state.index + 1
                    while index < state.snapshots.count, !state.isUserAction(at: index) {
                        index += 1
                    }
                    if index < state.snapshots.count {
                        state.index = index
                        return .action(.effect(.updateSnapshot))
                    }
                    else {
                        return .none
                    }
                    
                case .moveBackwardUser:
                    var index = state.index - 1
                    while index >= 0, !state.isUserAction(at: index) {
                        index -= 1
                    }
                    if index >= 0 {
                        state.index = index
                        return .action(.effect(.updateSnapshot))
                    }
                    else {
                        return .none
                    }

                case .updateJumpStepInput(let str):
                    state.jumpStepInput = str
                    return .none
                    
                case .jumpTo(let step):
                    return state.jump(to: step) ? .action(.effect(.updateSnapshot)) : .none
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
