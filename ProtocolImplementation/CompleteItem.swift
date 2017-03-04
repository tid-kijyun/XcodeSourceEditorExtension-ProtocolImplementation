//
//  CompleteItem.swift
//  XcodeSourceEditorExtension-ProtocolImplementation
//
//  Created by Atsushi Kiwaki on 2017/03/04.
//  Copyright © 2017 Atsushi Kiwaki. All rights reserved.
//

import Himotoki

final class CompletionItem {
    var descriptionKey: String   = ""
    var kind: String             = ""
    var name: String             = ""
    var sourcetext: String?      = ""
    var typeName: String?        = ""
    var associatedUSRs: String?  = ""
    var moduleName: String?      = ""
    var context: String?         = ""

    convenience init(descriptionKey: String,
                     kind: String,
                     name: String,
                     sourcetext: String?,
                     typeName: String?,
                     associatedUSRs: String?,
                     moduleName: String?,
                     context: String?) {
        self.init()
        self.descriptionKey = descriptionKey
        self.kind    = kind
        self.name = name
        self.sourcetext = sourcetext
        self.typeName = typeName
        self.associatedUSRs = associatedUSRs
        self.moduleName = moduleName
        self.context = context
    }

    var isMethod: Bool {
        return kind == "source.lang.swift.decl.function.method.instance"
    }
}

extension CompletionItem: Decodable {
    static func decode(_ e: Extractor) throws -> CompletionItem {
        return try CompletionItem(
            descriptionKey: e <| "descriptionKey",
            kind: e <| "kind",
            name: e <| "name",
            sourcetext: e <|? "sourcetext",
            typeName: e <|? "typeName",
            associatedUSRs: e <|? "associatedUSRs",
            moduleName: e <|? "moduleName",
            context: e <|? "context"
        )
    }
}
