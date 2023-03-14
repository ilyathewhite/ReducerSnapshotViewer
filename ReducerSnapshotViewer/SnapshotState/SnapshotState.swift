//
//  SnapshotState.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/8/23.
//

import Foundation
import FoundationEx
import ReducerArchitecture

enum SnapshotState: StoreNamespace {
    typealias PublishedValue = Void

    struct StoreEnvironment {
        let showDiff: (_ propertyName: String, _ oldValue: String, _ newValue: String) -> Void
    }

    enum MutatingAction {
        case toggleExpanded(property: String)
        case update([CodePropertyValuePair], from: [CodePropertyValuePair]?)
    }

    enum EffectAction {
        case showDiff(propertyName: String, oldValue: String, newValue: String)
    }

    enum RowValue {
        case same(String)
        case updated(old: String, new: String)
        
        var latest: String {
            switch self {
            case .same(let value):
                return value
            case let .updated(_, newValue):
                return newValue
            }
        }
        
        var isUpdated: Bool {
            switch self {
            case .same:
                return false
            case .updated:
                return true
            }
        }
        
        static func rowValue(old: String, new: String) -> Self {
            old == new ? .same(new) : .updated(old: old, new: new)
        }
    }
    
    struct Row: Identifiable {
        var isExpanded = false
        var property: String
        var value: RowValue
        
        var id: String {
            property
        }
        
        var isUpdated: Bool {
            value.isUpdated
        }
        
        var change: (old: String, new: String)? {
            switch value {
            case .same:
                return nil
            case let .updated(old, new):
                return (old, new)
            }
        }
        
        init(_ pair: CodePropertyValuePair) {
            self.property = pair.property
            self.value = .same(pair.value)
        }
    }
    
    struct StoreState {
        var rows: [Row]
    }
}

extension SnapshotState {
    @MainActor
    static func store(state: [CodePropertyValuePair]) -> Store {
        Store(identifier, .init(rows: state.map { .init($0) }), reducer: reducer(), env: nil)
    }
    
    @MainActor
    static func reducer() -> Reducer {
        .init(
            run: { state, action in
                switch action {
                case .toggleExpanded(let property):
                    guard let index = state.rows.firstIndex(where: { $0.property == property }) else {
                        assertionFailure()
                        return .none
                    }
                    state.rows[index].isExpanded.toggle()
                    
                case let .update(rows, prevRows):
                    guard rows.count == state.rows.count else {
                        state.rows = rows.map { .init($0) }
                        return .none
                    }
                    for index in rows.indices {
                        guard state.rows[index].property == rows[index].property else {
                            assertionFailure()
                            return .none
                        }
                        
                        let oldValue = prevRows?[index].value
                        let newValue = rows[index].value
                        state.rows[index].value = .rowValue(old: oldValue ?? newValue, new: newValue)
                    }
                }
                
                return .none
            },
            effect: { env, state, action in
                switch action {
                case let .showDiff(propertyName, oldValue, newValue):
                    env.showDiff(propertyName, oldValue, newValue)
                }
                return .none
            }
        )
    }
}
