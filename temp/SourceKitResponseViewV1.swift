import SwiftUI
import Foundation

struct SourceKitResponseView: View {
  let raws: [String: Any]
  var body: some View {
    List(raws.sorted(by: { $0.key < $1.key }), id: \.key) { item in
      HStack {
        Text(item.key)
        Spacer()
        if let value = item.value as? String {
          Text("\(value)")
        } else if let value = item.value as? Int64 {
          Text("\(value)")
        } else if let value = item.value as? Bool {
          let txt = "\(value)"
          Text(txt)
        } else if let value = item.value as? [String: Any] {
          SourceKitResponseView(raws: value)
        } else {
          Text("None imp")
        }
      }
    }
  }
}