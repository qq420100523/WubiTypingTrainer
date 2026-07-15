import Cocoa
import Foundation

setbuf(__stdoutp, nil)

func renderSVG(at svgPath: String, outputDir: String, sizes: [Int]) {
    let svgURL = URL(fileURLWithPath: svgPath)
    let data = try! Data(contentsOf: svgURL)
    guard let image = NSImage(data: data) else {
        print("ERROR: Could not create NSImage")
        exit(1)
    }
    let fileManager = FileManager.default
    try! fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
    for px in sizes {
        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        bitmapRep.size = NSSize(width: px, height: px)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)!
        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: CGFloat(px), height: CGFloat(px)).fill()
        let drawRect = NSRect(x: 0, y: 0, width: CGFloat(px), height: CGFloat(px))
        image.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
        let pngData = bitmapRep.representation(using: .png, properties: [:])
        try! pngData!.write(to: URL(fileURLWithPath: "\(outputDir)/icon_\(px)x\(px).png"))
    }
}

let args = CommandLine.arguments
let svgPath = args[1], outputDir = args[2]
let sizes = args[3].split(separator: ",").map { Int($0.trimmingCharacters(in: .whitespaces))! }
renderSVG(at: svgPath, outputDir: outputDir, sizes: sizes)
