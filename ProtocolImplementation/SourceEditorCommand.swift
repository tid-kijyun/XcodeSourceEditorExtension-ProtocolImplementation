//
//  SourceEditorCommand.swift
//  ProtocolImplementation
//
//  Created by Atsushi Kiwaki on 2017/03/04.
//  Copyright © 2017 Atsushi Kiwaki. All rights reserved.
//

import Foundation
import XcodeKit
import Himotoki
import Kanna

enum CommandError: Error {
    case error(String)
    case connectionFailed
    case timedOut
}

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    private static let Prefix     = "com.tid.ProtocolImplementation-for-Xcode.ProtocolImplementation"
    private let CompletionCommand = "\(Prefix).fromCompletion"
    private let SnippetCommand    = "\(Prefix).fromSnippet"

    private static let ServiceName = "com.tid.ProtocolImplementation-for-Xcode.SourceKittenHelper"
    fileprivate let connection = { () -> NSXPCConnection in
        let connection = NSXPCConnection(serviceName: ServiceName)
        connection.remoteObjectInterface = NSXPCInterface(with: SourceKittenHelperProtocol.self)
        return connection
    }()

    fileprivate let def = UserDefaults(suiteName: "\(Bundle.main.object(forInfoDictionaryKey: "TeamIdentifierPrefix") as? String ?? "")ProtocolImplementation-for-Xcode")

    deinit {
        connection.invalidate()
    }

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        var err: Error? = nil
        defer {
            completionHandler(err)
        }

        do {
            switch invocation.commandIdentifier {
            case CompletionCommand:
                try protocolImplementation(with: invocation)
            case SnippetCommand:
                try snippetImplementation(with: invocation)
            default:
                break
            }
        } catch {
            err = error
        }
    }
}

extension SourceEditorCommand {
    func getStructure(content: String) throws -> String {
        connection.resume()
        defer {
            connection.suspend()
        }

        guard let helper = connection.remoteObjectProxy as? SourceKittenHelperProtocol else {
            throw CommandError.connectionFailed
        }

        let semaphore = DispatchSemaphore(value: 0)
        var structure = ""
        helper.structure(content) {
            structure = $0
            semaphore.signal()
        }

        let res = semaphore.wait(timeout: DispatchTime.now() + Double(Int64(NSEC_PER_SEC) * 10) / Double(NSEC_PER_SEC))
        if res == .timedOut {
            throw CommandError.timedOut
        }
        return structure
    }

    func getInheritedTypeNames(content: String, offset: Int) throws -> [String] {
        let structure = try getStructure(content: content)
        guard let data = structure.data(using: .utf8),
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
            return []
        }
        let structureItem: StructureItem = try decodeValue(json)
        guard structureItem.isSwift else {
            return []
        }

        let substructure = structureItem.getSubstructure(offset: offset)
        return substructure?.inheritedtypes?.map { $0.name } ?? []
    }

    func protocolImplementation(with invocation: XCSourceEditorCommandInvocation) throws {
        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            throw CommandError.error("None selection")
        }

        let file    = "Anonymous.swift"
        let content = invocation.buffer.lines.componentsJoined(by: "")
        var offset = 0
        for i in 0 ..< selection.start.line {
            if let line = invocation.buffer.lines[i] as? String {
                offset += line.characters.count
            }
        }
        offset += selection.start.column

        let inheritedTypes = try getInheritedTypeNames(content: content, offset: offset)
        guard !content.isEmpty && offset >= 0 && !inheritedTypes.isEmpty else {
            return
        }

        let indentWidth = invocation.buffer.usesTabsForIndentation ? invocation.buffer.tabWidth : invocation.buffer.indentationWidth
        let indent      = String(repeating: invocation.buffer.usesTabsForIndentation ? "\t" : " ", count: indentWidth)
        let startDepth  = selection.start.column / indentWidth

        let items = try getComplete(file: file, content: content, offset: offset)
        var depth = startDepth
        var point = selection.start.line
        for inheritedType in inheritedTypes {
            for item in items {
                if item.isMethod {
                    let sources = item.sourcetext!.components(separatedBy: "\n")
                    if item.associatedUSRs?.contains(inheritedType) ?? false {
                        for source in sources {
                            depth -= source.hasPrefix("}") ? 1 : 0
                            let indent = String(repeating: indent, count: depth)
                            let object = "\(indent)\(source)"
                            invocation.buffer.lines.insert(object, at: point)
                            depth += source.hasSuffix("{") ? 1 : 0
                            point += 1
                        }

                        if inheritedType != inheritedTypes.last {
                            point += 1
                            invocation.buffer.lines.insert("\n", at: point)
                        }
                    }
                }
            }
        }
    }

    func getComplete(file: String, content: String, offset: Int) throws -> [CompletionItem] {
        connection.resume()
        defer {
            connection.suspend()
        }

        guard let helper = connection.remoteObjectProxy as? SourceKittenHelperProtocol else {
            throw CommandError.connectionFailed
        }

        let semaphore = DispatchSemaphore(value: 0)

        var result = ""
        helper.complete(file, content: content, offset: offset) {
            result = $0
            semaphore.signal()
        }

        let res = semaphore.wait(timeout: DispatchTime.now() + Double(Int64(NSEC_PER_SEC) * 10) / Double(NSEC_PER_SEC))
        if res == .timedOut {
            throw CommandError.timedOut
        }

        guard let data = result.data(using: .utf8),
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [[String: Any]] else {
            return []
        }
        let items: [CompletionItem] = try decodeArray(json)
        return items
    }

    func snippetImplementation(with invocation: XCSourceEditorCommandInvocation) throws {
        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            throw CommandError.error("None selection")
        }

        guard let configString = def?.object(forKey: "SnippetConfig") as? String else {
            throw CommandError.error("None snippet config")
        }
        let configJson = try JSONSerialization.jsonObject(with: configString.data(using: .utf8)!, options: .mutableContainers) as? [String: Any]
        let config: SnippetConfig = try decodeValue(configJson!)
        let content = invocation.buffer.lines.componentsJoined(by: "")

        var offset = 0
        for i in 0 ..< selection.start.line {
            if let line = invocation.buffer.lines[i] as? String {
                offset += line.characters.count
            }
        }
        offset += selection.start.column

        let inheritedTypes = try getInheritedTypeNames(content: content, offset: offset)
        guard !inheritedTypes.isEmpty else {
            return
        }

        let indentWidth = invocation.buffer.usesTabsForIndentation ? invocation.buffer.tabWidth : invocation.buffer.indentationWidth
        let indent = String(repeating: invocation.buffer.usesTabsForIndentation ? "\t" : " ", count: indentWidth)
        let startDepth  = selection.start.column / indentWidth
        let startIndent = String(repeating: indent, count: startDepth)

        let pattern = NSRegularExpression.escapedPattern(for: indent)
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        var point = selection.start.line
        for inheritedType in inheritedTypes {
            for snippet in config.snippets {
                guard snippet.key == inheritedType else {
                    continue
                }

                let sources = try getSnippet(directory: config.directory, path: snippet.path).components(separatedBy: "\n")
                var depth = 0
                if let first = sources.first {
                    depth   = regex.numberOfMatches(in: first, options: .reportCompletion, range: NSRange(0..<first.characters.count))
                }

                for source in sources {
                    let object = source.replacingOccurrences(of:  "^\(String(repeating: indent, count: depth))", with: "\(startIndent)", options: .regularExpression, range: nil)
                    invocation.buffer.lines.insert(object, at: point)
                    point += 1
                }

                if inheritedType != inheritedTypes.last {
                    point += 1
                    invocation.buffer.lines.insert("\n", at: point)
                }
            }
        }
    }

    func getSnippet(directory: String, path: String) throws -> String {
        connection.resume()
        defer {
            connection.suspend()
        }

        guard let helper = connection.remoteObjectProxy as? SourceKittenHelperProtocol else {
            throw CommandError.connectionFailed
        }


        let semaphore = DispatchSemaphore(value: 0)
        var text = ""
        helper.snippet("\(directory)/\(path).codesnippet") {
            text = $0
            semaphore.signal()
        }
        let res = semaphore.wait(timeout: DispatchTime.now() + Double(Int64(NSEC_PER_SEC) * 10) / Double(NSEC_PER_SEC))
        if res == .timedOut {
            throw CommandError.timedOut
        }

        guard let doc = XML(xml: text, encoding: .utf8),
            let string = doc.at_xpath("//string[position() = 2]")?.text else {
            throw CommandError.error("None snippet")
        }

        return string
    }
}
