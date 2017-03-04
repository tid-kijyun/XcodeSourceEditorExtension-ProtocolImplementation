//
//  StructureItem.swift
//  XcodeSourceEditorExtension-ProtocolImplementation
//
//  Created by Atsushi Kiwaki on 2017/03/04.
//  Copyright © 2017 Atsushi Kiwaki. All rights reserved.
//

import Himotoki

final class ElementItem {
    var kind: String = ""
    var offset: Int  = 0
    var length: Int  = 0

    convenience init(kind: String,
                     offset: Int,
                     length: Int) {
        self.init()
        self.kind = kind
        self.offset = offset
        self.length = length
    }
}

extension ElementItem: Decodable {
    static func decode(_ e: Extractor) throws -> ElementItem {
        return try ElementItem(
            kind: e <| "key.kind",
            offset: e <| "key.offset",
            length: e <| "key.length"
        )
    }
}

final class InheritedTypeItem {
    var name: String = ""

    convenience init(name: String) {
        self.init()
        self.name = name
    }
}


extension InheritedTypeItem: Decodable {
    static func decode(_ e: Extractor) throws -> InheritedTypeItem {
        return try InheritedTypeItem(
            name: e <| "key.name"
        )
    }
}

final class SubStructureItem {
    var bodylength: Int? = 0
    var nameoffset: Int = 0
    var substructure: [SubStructureItem]?
    var elements: [ElementItem]?
    var accessibility: String?
    var length: Int     = 0
    var runtime_name: String?
    var name: String?   = ""
    var inheritedtypes: [InheritedTypeItem]?
    var bodyoffset: Int? = 0
    var kind: String    = ""
    var offset: Int     = 0
    var namelength: Int = 0

    convenience init(bodylength: Int?,
                     nameoffset: Int,
                     substructure: [SubStructureItem]?,
                     elements: [ElementItem]?,
                     accessibility: String?,
                     length: Int,
                     runtime_name: String?,
                     name: String?,
                     inheritedtypes: [InheritedTypeItem]?,
                     bodyoffset: Int?,
                     kind: String,
                     offset: Int,
                     namelength: Int
        ) {
        self.init()
        self.bodylength = bodylength
        self.nameoffset = nameoffset
        self.substructure = substructure
        self.elements = elements
        self.accessibility = accessibility
        self.length = length
        self.runtime_name = runtime_name
        self.name = name
        self.inheritedtypes = inheritedtypes
        self.bodyoffset = bodyoffset
        self.kind = kind
        self.offset = offset
        self.namelength = namelength
    }

    var inheritedTypeNames: [String] {
        return self.inheritedtypes?.map { $0.name } ?? []
    }
}

extension SubStructureItem: Decodable {
    static func decode(_ e: Extractor) throws -> SubStructureItem {
        return try SubStructureItem(
            bodylength: e <|? "key.bodylength",
            nameoffset: e <| "key.nameoffset",
            substructure: e <||? "key.substructure",
            elements: e <||? "key.elements",
            accessibility: e <|? "key.accessibility",
            length: e <| "key.length",
            runtime_name: e <|? "key.runtime_name",
            name: e <|? "key.name",
            inheritedtypes: e <||? "key.inheritedtypes",
            bodyoffset: e <|? "key.bodyoffset",
            kind: e <| "key.kind",
            offset: e <| "key.offset",
            namelength: e <| "key.namelength"
        )
    }
}


final class StructureItem {
    var diagnostic_stage: String         = ""
    var substructure: [SubStructureItem] = []
    var offset: Int = 0
    var length: Int = 0

    convenience init(diagnostic_stage: String,
                     substructure: [SubStructureItem],
                     offset: Int,
                     length: Int) {
        self.init()
        self.diagnostic_stage = diagnostic_stage
        self.substructure = substructure
        self.offset = offset
        self.length = length
    }

    var isSwift: Bool {
        return diagnostic_stage.hasSuffix(".swift.parse")
    }

    func getSubstructure(offset: Int) -> SubStructureItem? {
        for sub in substructure {
            if let target = getSubstructure(sub: sub, offset: offset, depth: 0) {
                return target
            }
        }
        return nil
    }

    private func getSubstructure(sub: SubStructureItem, offset: Int, depth: Int) -> SubStructureItem? {
        let depth = depth + 1
        if let bodyoffset = sub.bodyoffset,
            let bodylength = sub.bodylength {
            if offset >= bodyoffset && offset <= bodyoffset + bodylength {
                if let substructure = sub.substructure {
                    for sub in substructure {
                        if let target = getSubstructure(sub: sub, offset: offset, depth: depth) {
                            return target
                        }
                    }
                }

                return sub
            }
        }

        guard let substructure = sub.substructure else {
            return nil
        }

        for sub in substructure {
            if let target = getSubstructure(sub: sub, offset: offset, depth: depth) {
                return target
            }
        }

        return nil
    }
}

extension StructureItem: Decodable {
    static func decode(_ e: Extractor) throws -> StructureItem {
        return try StructureItem(
            diagnostic_stage: e <| "key.diagnostic_stage",
            substructure: e <|| "key.substructure",
            offset: e <| "key.offset",
            length: e <| "key.length"
        )
    }
}

class BodyInfo {
    var depth: Int = 0
    var substructureItem: SubStructureItem

    init(depth: Int, substructureItem: SubStructureItem) {
        self.depth = depth
        self.substructureItem = substructureItem
    }
}
