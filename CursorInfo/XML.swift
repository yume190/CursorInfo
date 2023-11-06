//
//  XML.swift
//  CursorInfo
//
//  Created by Tangram Yume on 2023/11/6.
//

import Foundation
import SWXMLHash

func removeXMLTags(from input: String) -> String {
    do {
        let regex = try NSRegularExpression(pattern: "<[^>]+>")
        let range = NSMakeRange(0, input.utf16.count)
        return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "")
    } catch {
        print("Error in regex pattern: \(error)")
        return input
    }
}
