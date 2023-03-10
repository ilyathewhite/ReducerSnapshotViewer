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
    static let defaultValue: Font = .system(size: 14).monospaced()
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
    
    enum Tag {}
    typealias WidthKey = FirstMeasurementKey<CGFloat, Tag>
    @State private var bottomStackHeight: CGFloat?
    
    init(charCount: Int) {
        self.charCount = charCount
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
        .frame(width: idealWidth)
    }
}

extension View {
    func fitCodeString(charCount: Int = codeStringDefaultMaxWidth) -> some View {
        modifier(FitCodeStringWidth(charCount: charCount))
    }
}
