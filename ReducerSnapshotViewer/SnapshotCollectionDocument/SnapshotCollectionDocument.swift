//
//  SnapshotCollectionDocument.swift
//  ReducerSnapshotViewer
//
//  Created by Ilya Belenkiy on 3/10/23.
//

import SwiftUI
import ReducerArchitecture
import UniformTypeIdentifiers

struct SnapshotCollectionDocument: FileDocument {
    static var readableContentTypes = [UTType.json]

    enum Error: Swift.Error {
        case invalidContent
        case notImplemented
    }

    let snapshotCollection: ReducerSnapshotCollection

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw Error.invalidContent
        }
        
        snapshotCollection = try JSONDecoder().decode(ReducerSnapshotCollection.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw Error.notImplemented
    }
}
