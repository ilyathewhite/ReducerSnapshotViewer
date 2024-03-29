//
//  ReducerSnapshotViewerApp.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/8/23.
//

import SwiftUI

@main
struct ReducerSnapshotViewerApp: App {
    var body: some Scene {
        DocumentGroup(viewing: SnapshotCollectionDocument.self) {
            SnapshotCollectionDocumentView(document: $0.document)
        }
    }
}
