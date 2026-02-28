import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
  fatalError("No graphics context")
}

let rect = CGRect(origin: .zero, size: CGSize(width: 1024, height: 1024))
let radius: CGFloat = 220
let path = NSBezierPath(roundedRect: rect.insetBy(dx: 24, dy: 24), xRadius: radius, yRadius: radius)
path.addClip()

let colors = [
  NSColor(calibratedRed: 0.05, green: 0.58, blue: 0.96, alpha: 1.0).cgColor,
  NSColor(calibratedRed: 0.03, green: 0.18, blue: 0.52, alpha: 1.0).cgColor
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])

ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.12).cgColor)
ctx.setLineWidth(2)
for i in stride(from: 120, through: 900, by: 100) {
  ctx.move(to: CGPoint(x: CGFloat(i), y: 120))
  ctx.addLine(to: CGPoint(x: CGFloat(i), y: 900))
  ctx.strokePath()

  ctx.move(to: CGPoint(x: 120, y: CGFloat(i)))
  ctx.addLine(to: CGPoint(x: 900, y: CGFloat(i)))
  ctx.strokePath()
}

let circleRect = CGRect(x: 230, y: 230, width: 560, height: 560)
ctx.setFillColor(NSColor.black.withAlphaComponent(0.28).cgColor)
ctx.fillEllipse(in: circleRect)

let hammer = NSString(string: "🔨")
let attrs: [NSAttributedString.Key: Any] = [
  .font: NSFont.systemFont(ofSize: 360),
]
let textSize = hammer.size(withAttributes: attrs)
let textRect = CGRect(
  x: (1024 - textSize.width) / 2,
  y: (1024 - textSize.height) / 2 - 20,
  width: textSize.width,
  height: textSize.height
)
hammer.draw(in: textRect, withAttributes: attrs)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
  fatalError("Failed to encode PNG")
}

let out = URL(fileURLWithPath: "/Users/yume/git/yume/CursorInfo/vscode-lite/src-tauri/icons/icon.png")
try png.write(to: out)
print("Wrote icon.png")
