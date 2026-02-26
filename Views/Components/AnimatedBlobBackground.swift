import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Blob configuration

struct BlobConfig {
    let phaseX: Double
    let phaseY: Double
    let speedX: Double
    let speedY: Double
    let relativeSize: CGFloat
    let colorIndex: Int
}

let blobConfigs: [BlobConfig] = [
    BlobConfig(phaseX: 0.0,  phaseY: 0.0,  speedX: 0.37, speedY: 0.29, relativeSize: 0.85, colorIndex: 0),
    BlobConfig(phaseX: 1.2,  phaseY: 2.1,  speedX: 0.23, speedY: 0.41, relativeSize: 0.75, colorIndex: 1),
    BlobConfig(phaseX: 3.5,  phaseY: 0.7,  speedX: 0.51, speedY: 0.19, relativeSize: 0.70, colorIndex: 2),
    BlobConfig(phaseX: 0.9,  phaseY: 3.3,  speedX: 0.17, speedY: 0.53, relativeSize: 0.65, colorIndex: 3),
    BlobConfig(phaseX: 2.3,  phaseY: 1.5,  speedX: 0.43, speedY: 0.31, relativeSize: 0.60, colorIndex: 0),
]

// MARK: - Animated blob background (Apple Music–style)

struct AnimatedBlobBackground: View {
    let palette: [Color]
    let time: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Color.black.opacity(0.55)

                ForEach(blobConfigs.indices, id: \.self) { i in
                    let cfg = blobConfigs[i]
                    let color = palette.isEmpty ? Color.blue : palette[cfg.colorIndex % palette.count]
                    let diameter = min(w, h) * cfg.relativeSize
                    let cx = w * 0.5 + (w * 0.38) * sin(time * cfg.speedX + cfg.phaseX)
                    let cy = h * 0.5 + (h * 0.38) * cos(time * cfg.speedY + cfg.phaseY)

                    Ellipse()
                        .fill(color.opacity(0.82))
                        .frame(width: diameter, height: diameter * 0.8)
                        .position(x: cx, y: cy)
                }
            }
            .blur(radius: 72)
        }
        .clipped()
        .allowsHitTesting(false)
    }
}

// MARK: - Cross-platform image palette extraction

#if os(macOS)
import AppKit

extension NSImage {
    var averageColor: NSColor? { quadrantPalette.first }

    var quadrantPalette: [NSColor] {
        guard let tiffData = tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else { return [] }
        return ciImage.quadrantColors.map { r, g, b in
            NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
        }
    }
}
#else
import UIKit

extension UIImage {
    var averageColor: UIColor? { quadrantPalette.first }

    var quadrantPalette: [UIColor] {
        guard let cgImage = self.cgImage,
              let ciImage = CIImage(image: self) else { return [] }
        let _ = cgImage // silence unused warning
        return ciImage.quadrantColors.map { r, g, b in
            UIColor(red: r, green: g, blue: b, alpha: 1)
        }
    }
}
#endif

// MARK: - Shared CIImage quadrant sampling

private extension CIImage {
    /// Returns (r, g, b) tuples for the average colour of each quadrant (TL, TR, BL, BR).
    var quadrantColors: [(CGFloat, CGFloat, CGFloat)] {
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        let full = extent
        let hw = full.width / 2
        let hh = full.height / 2

        let quadrants: [CGRect] = [
            CGRect(x: full.minX,      y: full.minY + hh, width: hw, height: hh),
            CGRect(x: full.minX + hw, y: full.minY + hh, width: hw, height: hh),
            CGRect(x: full.minX,      y: full.minY,       width: hw, height: hh),
            CGRect(x: full.minX + hw, y: full.minY,       width: hw, height: hh),
        ]

        return quadrants.compactMap { rect in
            let filter = CIFilter.areaAverage()
            filter.inputImage = self
            filter.extent = rect
            guard let output = filter.outputImage else { return nil }

            var pixel = [UInt8](repeating: 0, count: 4)
            context.render(output,
                           toBitmap: &pixel,
                           rowBytes: 4,
                           bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                           format: .RGBA8,
                           colorSpace: nil)
            return (CGFloat(pixel[0]) / 255, CGFloat(pixel[1]) / 255, CGFloat(pixel[2]) / 255)
        }
    }
}
