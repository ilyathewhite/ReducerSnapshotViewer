//
//  SnapshotActionView.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/8/23.
//

import SwiftUI

struct SnapshotActionView: View {
    @Environment(\.codingFont) var codingFont
    
    enum Mode {
        case input, stateChange, output
    }
    
    let action: String?
    let mode: Mode
    
    static func actionText(action: String, font: Font) -> some View {
        ScrollView {
            Text(action)
                .font(font)
                .padding(.vertical)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    static func arrowIconName(mode: Mode) -> String? {
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
    static func arrow(mode: Mode) -> some View {
        if let iconName = arrowIconName(mode: mode) {
            Image(systemName: iconName)
                .font(.largeTitle.bold())
                .foregroundColor(.secondary)
        }
    }
    
    static func actionContent(action: String, mode: Mode, font: Font) -> some View {
        let padding: CGFloat = 15
        return HStack(spacing: padding) {
            actionText(action: action, font: font)
            Spacer()
            arrow(mode: mode)
        }
        .padding(.horizontal, padding)
    }
    
    var body: some View {
        if let action {
            Self.actionContent(action: action, mode: mode, font: codingFont)
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
            SnapshotActionView(action: inputAction, mode: .input)
                .border(Color.black)
            SnapshotActionView(action: effect, mode: .output)
                .border(Color.black)
            SnapshotActionView(action: nil, mode: .stateChange)
                .border(Color.black)
        }
    }
}
