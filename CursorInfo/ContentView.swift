//
//  ContentView.swift
//  CursorInfo
//
//  Created by Tangram Yume on 2023/11/6.
//

import SwiftUI
import STTextViewUI
import NeonPlugin
import SwiftUI
import STTextViewUI
import NeonPlugin
import SKClient

struct ContentView: View {
  @State private var text: AttributedString = ""
  @State private var selection: NSRange?

  @State
  var raws: [String: Any] = [:]
  var body: some View {
    HStack {
      STTextViewUI.TextView(
        text: $text,
        selection: $selection,
        options: [
          .wrapLines,
          .highlightSelectedLine,
        ],
        plugins: [
          NeonPlugin(theme: .default2, language: .swift),
          SKPlugin(),
          // LSPPlugin(),
        ]
      )
      .textViewFont(.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular))
      .onAppear {
        loadContent()
      }
      .onReceive(NotificationCenter.default.publisher(for: .sk)) { notification in
        let res = notification.userInfo?["res"] as? SourceKitResponse
        DispatchQueue.main.async {
          self.raws = res?.raw ?? [:]
        }
        print(raws)
      }
      SourceKitResponseView(raws)
        .frame(width: 400)
    }.background(Color.black)
  }
  
  private func loadContent() {
    self.text = AttributedString("""
    struct A {
      let a = 1
      let b = 2
      func abcd() {
        print(a, b)
        let aaa = A()
      }
    }
    """)
  }
}

#Preview {
  ContentView()
}
