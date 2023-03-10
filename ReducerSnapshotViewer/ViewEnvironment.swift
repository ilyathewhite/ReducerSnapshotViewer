//
//  ViewEnvironment.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/9/23.
//

import SwiftUI
import SwiftUIEx
import FoundationEx

private struct CodingFontKey: EnvironmentKey {
    static let defaultValue: Font = .system(size: 12).monospaced()
}

extension EnvironmentValues {
    var codingFont: Font {
        get { self[CodingFontKey.self] }
        set { self[CodingFontKey.self] = newValue }
    }
}

struct FitCodeStringWidth: ViewModifier {
    @Environment(\.codingFont) var codingFont
    @State private var idealWidth: CGFloat?
    let charCount: Int
    let fixedWidth: Bool
    
    enum Tag {}
    typealias WidthKey = FirstMeasurementKey<CGFloat, Tag>
    @State private var bottomStackHeight: CGFloat?
    
    init(charCount: Int, fixedWidth: Bool) {
        self.charCount = charCount
        self.fixedWidth = fixedWidth
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            content
            Text(String(repeating: " ", count: charCount))
                .fixedSize()
                .font(codingFont)
                .measureWidth(WidthKey.self, save: { idealWidth = $0 })
                .hidden()
        }
        .frame(minWidth: fixedWidth ? nil : idealWidth)
        .frame(width: fixedWidth ? idealWidth : nil)
    }
}

extension View {
    func fitCodeString(charCount: Int = codeStringDefaultMaxWidth, fixedWidth: Bool) -> some View {
        modifier(FitCodeStringWidth(charCount: charCount, fixedWidth: fixedWidth))
    }
}
