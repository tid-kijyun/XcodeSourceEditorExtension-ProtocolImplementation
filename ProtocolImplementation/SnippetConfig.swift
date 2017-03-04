//
//  SnippetConfig.swift
//  XcodeSourceEditorExtension-ProtocolImplementation
//
//  Created by Atsushi Kiwaki on 2017/03/04.
//  Copyright © 2017 Atsushi Kiwaki. All rights reserved.
//

import Himotoki

final class Snippet {
    var key: String = ""
    var path: String = ""

    convenience init(key: String,
                     path: String) {
        self.init()
        self.key = key
        self.path = path
    }
}

extension Snippet: Decodable {
    static func decode(_ e: Extractor) throws -> Snippet {
        return try Snippet(
            key: e <| "key",
            path: e <| "path"
        )
    }
}

final class SnippetConfig {
    var directory: String = ""
    var snippets: [Snippet] = []

    convenience init(directory: String,
                     snippets: [Snippet]) {
        self.init()
        self.directory = directory
        self.snippets = snippets
    }
}

extension SnippetConfig: Decodable {
    static func decode(_ e: Extractor) throws -> SnippetConfig {
        return try SnippetConfig(
            directory: e <| "Directory",
            snippets: e <|| "Snippets"
        )
    }
}
