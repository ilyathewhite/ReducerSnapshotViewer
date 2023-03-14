//
//  SnapshotActionView.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/8/23.
//

import SwiftUI
import SwiftUIEx

struct SnapshotActionView: View {
    @Environment(\.codingFont) var codingFont
    
    enum Mode {
        case input, stateChange, output
    }
    
    let action: String?
    let mode: Mode
    let nestedLevel: Int
    
    enum ArrowHeightTag {}
    typealias ArrowHeightKey = MeasurementKey<CGFloat, ArrowHeightTag>
    @State private var arrowHeight: CGFloat?
    
    func actionText(action: String, font: Font) -> some View {
        ScrollView {
            Text(action)
                .textSelection(.enabled)
                .font(font)
                .fitCodeString(fixedWidth: false)
                .padding(.vertical)
        }
    }
    
    func arrowIconName(mode: Mode) -> String? {
        switch mode {
        case .input:
            return "arrow.right"
        case .stateChange:
            return nil
        case .output:
            return "arrow.left"
        }
    }
    
    @ViewBuilder
    func arrow(mode: Mode) -> some View {
        if let iconName = arrowIconName(mode: mode) {
            Image(systemName: iconName)
                .font(.largeTitle.bold())
                .foregroundColor(.secondary)
                .background(nestedLevelText)
                .measureHeight(ArrowHeightKey.self) { arrowHeight = $0 }
        }
    }
    
    @ViewBuilder
    var nestedLevelText: some View {
        if nestedLevel > 0 {
            Text(String(nestedLevel))
                .font(codingFont)
                .offset(x: 0, y: arrowHeight ?? 0)
        }
    }
    
    func actionContent(action: String, mode: Mode, font: Font) -> some View {
        let padding: CGFloat = 15
        return HStack(spacing: padding) {
            actionText(action: action, font: font)
            Spacer()
            arrow(mode: mode)
                .measurement(FixedWidthKey.self) { proxy in
                    proxy.size.width + 2 * padding
                }
        }
        .padding(.horizontal, padding)
    }
    
    var body: some View {
        if let action {
            actionContent(action: action, mode: mode, font: codingFont)
        }
        else {
            Text("State Change")
                .font(.largeTitle)
                .foregroundColor(.secondary)
        }
    }
}

struct SnapshotActionView_Previews: PreviewProvider {
    static let inputAction = """
    .mutating(
       .toggleNote(fret: 2, string: 5),
       animated: false,
       nil
    )
    """
    
    static let effect = """
    .actions([
       .mutating(
          .toggleNote(fret: 2, string: 5),
          animated: false,
          nil
       ),
       .mutating(.endUpdate, animated: false, nil)
    ])
    """
    
    static var previews: some View {
        VStack(spacing: 50) {
            SnapshotActionView(action: inputAction, mode: .input, nestedLevel: 2)
                .border(Color.black)
            SnapshotActionView(action: effect, mode: .output, nestedLevel: 2)
                .border(Color.black)
            SnapshotActionView(action: nil, mode: .stateChange, nestedLevel: 2)
                .border(Color.black)
        }
    }
}
