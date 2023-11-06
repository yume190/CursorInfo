//
//  Theme.swift
//  CursorInfo
//
//  Created by Tangram Yume on 2023/11/6.
//

import Foundation
import Cocoa
import NeonPlugin
import SwiftUI

extension Theme {
  public static let default2 = Theme(
    [
      "string": Theme.Value(color: Color(NSColor(red: 153 / 255, green: 0, blue: 0, alpha: 1)), font: nil),
      "number": Theme.Value(color: Color(NSColor(red: 28 / 255, green: 0 / 255, blue: 207 / 255, alpha: 1)), font: nil),
      
      "keyword": Theme.Value(color: Color(NSColor(red: 155 / 255, green: 35 / 255, blue: 147 / 255, alpha: 1)), font: Font(NSFont.monospacedSystemFont(ofSize: 0, weight: .bold))),
      "include": Theme.Value(color: Color(NSColor(red: 155 / 255, green: 35 / 255, blue: 147 / 255, alpha: 1)), font: nil),
      "constructor": Theme.Value(color: Color(NSColor(red: 155 / 255, green: 35 / 255, blue: 147 / 255, alpha: 1)), font: Font(NSFont.monospacedSystemFont(ofSize: 0, weight: .bold))),
      "keyword.function": Theme.Value(color: Color(NSColor(red: 50 / 255, green: 109 / 255, blue: 116 / 255, alpha: 1)), font: nil),
      "keyword.return": Theme.Value(color: Color(NSColor(red: 155 / 255, green: 35 / 255, blue: 147 / 255, alpha: 1)), font: nil),
      "variable.builtin": Theme.Value(color: Color(NSColor(red: 50 / 255, green: 109 / 255, blue: 116 / 255, alpha: 1)), font: nil),
      "boolean": Theme.Value(color: Color(NSColor(red: 155 / 255, green: 35 / 255, blue: 147 / 255, alpha: 1)), font: nil),
      
      "type": Theme.Value(color: Color(NSColor(red: 11 / 255, green: 79 / 255, blue: 121 / 255, alpha: 1)), font: nil),
      
      "function.call": Theme.Value(color: Color(NSColor(red: 11 / 255, green: 79 / 255, blue: 121 / 255, alpha: 1)), font: nil),
      
      "variable": Theme.Value(color: Color(NSColor.yellow), font: nil),
      "property": Theme.Value(color: Color(NSColor(red: 50 / 255, green: 109 / 255, blue: 116 / 255, alpha: 1)), font: nil),
      "method": Theme.Value(color: Color(NSColor(red: 50 / 255, green: 109 / 255, blue: 116 / 255, alpha: 1)), font: nil),
      "parameter": Theme.Value(color: Color(NSColor.white), font: nil),
      "comment": Theme.Value(color: Color(NSColor.green), font: nil),
      "operator": Theme.Value(color: Color(NSColor.white), font: nil),
      
        .default: Theme.Value(color: Color(NSColor.textColor), font: Font(NSFont.monospacedSystemFont(ofSize: 0, weight: .regular)))
    ]
  )
}
