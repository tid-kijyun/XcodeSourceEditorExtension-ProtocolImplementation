//
//  SourceKittenHelper.swift
//  XcodeSourceEditorExtension-ProtocolImplementation
//
//  Created by Atsushi Kiwaki on 2017/03/04.
//  Copyright © 2017 Atsushi Kiwaki. All rights reserved.
//

import Foundation
import SourceKittenFramework

@objc class SourceKittenHelper: NSObject, SourceKittenHelperProtocol {
    @objc func structure(_ content: String, withReply reply: @escaping (String) -> Void) {
        let file = File(contents: content)
        let st   = Structure(file: file)

        reply(st.description)
    }

    @objc func complete(_ file: String, content: String, offset: Int, withReply reply: @escaping (String) -> Void) {
        let completionItems = CodeCompletionItem.parse(response: Request.codeCompletionRequest(file: file,
                                                                                               contents: content,
                                                                                               offset: Int64(offset),
                                                                                               arguments: [
                                                                                                "-c",
                                                                                                file,
                                                                                                "-target",
                                                                                                "arm64-apple-ios9.0",
                                                                                                "-sdk",
                                                                                                "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS10.2.sdk"
            ]).send())

        reply(completionItems.description)
    }

    func snippet(_ file: String, withReply reply: @escaping (String) -> Void) {
        guard let text = try? String(contentsOfFile: file, encoding: .utf8) else {
            reply("")
            return
        }

        reply(text)
    }
}
