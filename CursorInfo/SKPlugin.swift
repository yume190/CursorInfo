//
//  SKPlugin.swift
//  CursorInfo
//
//  Created by Tangram Yume on 2023/11/6.
//

import Foundation
import STTextView
import Cocoa
import SKClient
import SwiftUI

extension Notification.Name {
  static let sk = Notification.Name(rawValue: "com.yume190.sk")
}

public class Coordinator {
  let textView: STTextView

  init(textView: STTextView) {
    self.textView = textView
    textView.backgroundColor = .controlBackgroundColor

    NotificationCenter.default.addObserver(
      forName: STTextView.didChangeSelectionNotification,
      object: textView,
      queue: .main) { [weak textView] notification in
        guard let object = notification.object as? STTextView else { return }
        guard textView == object else { return }
        
        let range = object.selectedRange()
        guard range.length == 0 else { return }
        
        let code = object.string
        do {
          let client = SKClient(code: code)
          try client.editorOpen()
          defer {
            _ = try? client.editorClose()
          }
          let res = try client.cursorInfo(range.location)
          NotificationCenter.default.post(name: .sk, object: nil, userInfo: ["res": res])

        } catch {
          print(error)
        }
      }
  }
}

public struct SKPlugin: STPlugin {
  public func setUp(context: any Context) {}

  public func makeCoordinator(context: CoordinatorContext) -> Coordinator {
    Coordinator(textView: context.textView)
  }

  public func tearDown() {}
}
