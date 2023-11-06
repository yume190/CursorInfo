//
//  SourceKitResponseView.swift
//  CursorInfo
//
//  Created by Tangram Yume on 2023/11/6.
//

import SwiftUI
import Foundation
import SKClient

struct SourceKitResponseView: View {
  let raws: Any
  let root: Bool
  
  init(_ raws: Any) {
    self.init(raws: raws, root: true)
  }
  
  private init(raws: Any, root: Bool = false) {
    self.raws = raws
    self.root = root
  }
  
  var body: some View {
    rootCheck
  }
  
  @ViewBuilder
  var rootCheck: some View {
    if root {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 8) {
          content
        }
        .padding()
        //        .frame(maxWidth: .infinity)
      }
      
    } else {
      content
    }
  }
  
  @ViewBuilder
  var content: some View {
    if let value = raws as? String {
      Text("\(value)")
    } else if let value = raws as? Int64 {
      Text("\(value)")
    } else if let value = raws as? Bool {
      let txt = "\(value)"
      Text(txt)
    } else if let value = raws as? [String: Any] {
      ForEach(value.sorted(by: { $0.key < $1.key }), id: \.key) { item in
        let text = item.value as? String
        VStack(alignment: .leading, spacing: 8) {
          Text(item.key)
            .font(Font.system(size: 20))
            .lineLimit(1)
            .multilineTextAlignment(.leading)
          
          SourceKitResponseView(raws: item.value)
            .font(Font.system(size: 16))
            .multilineTextAlignment(.leading)
            .padding(.all, 4)
          
          if item.key.contains("_decl"), let xml = text?.xmlValue {
            Text("* \(xml)")
              .font(Font.system(size: 16))
              .overlay(
                Rectangle()
                  .frame(height: 1) // Adjust the height as needed
                  .foregroundColor(Color.green) // Adjust the color as needed
                  .padding(.top, 16) // Adjust the spacing from the text
              )
          }
          
          if item.key.contains("usr"), let usr = USR(text)?.demangle() {
            Text("* \(usr)")
              .font(Font.system(size: 16))
              .overlay(
                Rectangle()
                  .frame(height: 1) // Adjust the height as needed
                  .foregroundColor(Color.green) // Adjust the color as needed
                  .padding(.top, 16) // Adjust the spacing from the text
              )
          }
        }
        // .border(Color.green, width: 3)
      }
    } else if let value = raws as? [Any] {
      ForEach(Array(value.enumerated()), id: \.offset) { index, item in
        VStack {
          let title = "[\(index)]"
          Text(title)
            .alignmentGuide(.leading) { d in d[.trailing] }
          Spacer(minLength: 16)
          SourceKitResponseView(raws: item)
            .alignmentGuide(.trailing) { d in d[.trailing] }
        }
      }
    } else {
      Text("No Implement")
    }
  }
}

extension String {
  var xmlValue: String {
    removeXMLTags(from: self)
  }
}

#Preview {
  SourceKitResponseView([
    "a":"aaaa",
    "b":"bbbb",
    "c_decl": "<decl.var.local><syntaxtype.keyword>let</syntaxtype.keyword> <decl.name>aaa</decl.name>: <decl.var.type><ref.struct usr=\"s:4temp1AV\">A</ref.struct></decl.var.type></decl.var.local>",
  ])
}
