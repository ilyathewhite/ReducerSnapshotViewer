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
    typealias StoreEnvironment = Never
    typealias EffectAction = Never

    enum MutatingAction {
        case toggleExpanded(property: String)
        case update([CodePropertyValuePair], resetUpdateStatus: Bool)
    }
    
    struct Row: Identifiable {
        var isUpdated = false
        var isExpanded = false
        var property: String
        var value: String
        
        var id: String {
            property
        }
        
        init(_ pair: CodePropertyValuePair) {
            self.property = pair.property
            self.value = pair.value
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
        .init { state, action in
            switch action {
            case .toggleExpanded(let property):
                guard let index = state.rows.firstIndex(where: { $0.property == property }) else {
                    assertionFailure()
                    return .none
                }
                state.rows[index].isExpanded.toggle()
                
            case let .update(rows, resetUpdateStatus):
                guard rows.count == state.rows.count else {
                    state.rows = rows.map { .init($0) }
                    return .none
                }
                for index in rows.indices {
                    guard state.rows[index].property == rows[index].property else {
                        assertionFailure()
                        return .none
                    }
                    state.rows[index].isUpdated = resetUpdateStatus ? false : (state.rows[index].value != rows[index].value)
                    state.rows[index].value = rows[index].value
                }
            }

            return .none
        }
    }
}
