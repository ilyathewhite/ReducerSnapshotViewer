//
//  StringDiffUI.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/10/23.
//

import Foundation

import FoundationEx
import SwiftUI
import ReducerArchitecture


struct StringView: View {
    let title: String
    let string: AttributedString
    
    init(title: String, string: AttributedString) {
        self.title = title
        self.string = string
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .padding()
                .font(.title3)
            Divider()
            ScrollView {
                Text(string)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fitCodeString(charCount: Int(1.5 * Double(codeStringDefaultMaxWidth)), fixedWidth: false)
                    .padding()
            }
        }
    }
}

extension StringDiff: StoreUIWrapper {
    struct ContentView: StoreContentView {
        typealias StoreWrapper = StringDiff
        @ObservedObject var store: Store
        
        init(store: Store) {
            self.store = store
        }
        
        @Environment(\.codingFont) var codingFont
        
        func styled(_ string: AttributedString) -> AttributedString {
            var string = string
            let range = string.startIndex..<string.endIndex
            string[range].font = codingFont
            return string
        }

        var body: some View {
            HStack(spacing: 0) {
                StringView(title: store.state.string1Caption, string: styled(store.state.string1))
                Divider()
                StringView(title: store.state.string2Caption, string: styled(store.state.string2))
            }
        }
    }
}

struct StringDiff_Previews: PreviewProvider {
    
    static let store = StringDiff.store(
        title: "Testing Diff",
        string1Caption: "Old Value",
        string1: "one two three",
        string2Caption: "New Value",
        string2: "one four three five"
    )
    
    static var previews: some View {
        StringDiff.ContentView(store: store)
    }
}
