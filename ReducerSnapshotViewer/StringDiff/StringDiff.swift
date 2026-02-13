//
//  StringDiff.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/10/23.
//

import Foundation

import ReducerArchitecture

enum StringDiff: StoreNamespace {
    typealias PublishedValue = Void
    
    typealias StoreEnvironment = Never
    typealias EffectAction = Never
    typealias MutatingAction = Void
        
    struct StoreState {
        let title: String
        let string1Caption: String
        let string1: AttributedString
        let string2Caption: String
        let string2: AttributedString
        
        static func removalsAttributedString(
            from otherString: String,
            to string: String,
            style: (inout AttributedString, AttributedString.Index) -> Void
        )
        -> AttributedString
        {
            var otherAttrString = AttributedString(otherString)
            let diffFromOther = string.difference(from: otherString)
            for removal in diffFromOther.removals {
                guard case let .remove(offset: offset, element: _, associatedWith: _) = removal else {
                    assertionFailure()
                    continue
                }
                let index = otherAttrString.index(otherAttrString.startIndex, offsetByCharacters: offset)
                style(&otherAttrString, index)
            }
            return otherAttrString
        }
        
        init(title: String, string1Caption: String, string1: String, string2Caption: String, string2: String) {
            self.title = title
            self.string1Caption = string1Caption
            self.string2Caption = string2Caption

            self.string1 = Self.removalsAttributedString(from: string1, to: string2) { str, index in
                str[index...index].backgroundColor = .red.opacity(0.2)
            }
            
            self.string2 = Self.removalsAttributedString(from: string2, to: string1) { str, index in
                str[index...index].backgroundColor = .green.opacity(0.2)
            }
        }
    }
}

extension StringDiff {
    @MainActor
    static func store(title: String, string1Caption: String, string1: String, string2Caption: String, string2: String) -> Store {
        let state: StoreState = .init(
            title: title,
            string1Caption: string1Caption,
            string1: string1,
            string2Caption: string2Caption,
            string2: string2
        )
        return Store(state, env: nil)
    }
}
