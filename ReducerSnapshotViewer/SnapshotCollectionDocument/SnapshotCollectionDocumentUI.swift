//
//  SnapshotCollectionDocumentUI.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/10/23.
//

import SwiftUI

struct SnapshotCollectionDocumentView: View {
    let document: SnapshotCollectionDocument

    var body: some View {
        let store = SnapshotCollectionViewer.store(snapshotCollection: document.snapshotCollection)
        SnapshotCollectionViewer.ContentView(store: store)
    }
}
