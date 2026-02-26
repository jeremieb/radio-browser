#if os(macOS)
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit

// MARK: - Blob configuration

struct BlobConfig {
    let phaseX: Double
    let phaseY: Double
    let speedX: Double
    let speedY: Double
    let relativeSize: CGFloat   // fraction of the view's shorter dimension
    let colorIndex: Int         // which palette color to use
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
    let time: Double            // seconds since some epoch, drives the animation

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Dark base so blobs have something to glow against
                Color.black.opacity(0.55)

                ForEach(blobConfigs.indices, id: \.self) { i in
                    let cfg = blobConfigs[i]
                    let color = palette.isEmpty ? Color.blue : palette[cfg.colorIndex % palette.count]
                    let diameter = min(w, h) * cfg.relativeSize

                    // Lissajous-like drift: keeps blobs within the view bounds
                    let cx = w * 0.5 + (w * 0.38) * sin(time * cfg.speedX + cfg.phaseX)
                    let cy = h * 0.5 + (h * 0.38) * cos(time * cfg.speedY + cfg.phaseY)

                    Ellipse()
                        .fill(color.opacity(0.82))
                        .frame(width: diameter, height: diameter * 0.8)
                        .position(x: cx, y: cy)
                }
            }
            .blur(radius: 72)          // the heavy blur is what makes it look like Apple Music
        }
        .clipped()
        .allowsHitTesting(false)
    }
}

// MARK: - NSImage palette extraction

extension NSImage {
    var averageColor: NSColor? {
        quadrantPalette.first
    }

    /// Returns the average color of each image quadrant (TL, TR, BL, BR),
    /// giving a natural 4-color palette that reflects the artwork's actual hues.
    var quadrantPalette: [NSColor] {
        guard let tiffData = tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else {
            return []
        }

        let context = CIContext(options: [.workingColorSpace: NSNull()])
        let full = ciImage.extent
        let hw = full.width / 2
        let hh = full.height / 2

        let quadrants: [CGRect] = [
            CGRect(x: full.minX,      y: full.minY + hh, width: hw, height: hh), // top-left
            CGRect(x: full.minX + hw, y: full.minY + hh, width: hw, height: hh), // top-right
            CGRect(x: full.minX,      y: full.minY,       width: hw, height: hh), // bottom-left
            CGRect(x: full.minX + hw, y: full.minY,       width: hw, height: hh), // bottom-right
        ]

        return quadrants.compactMap { rect -> NSColor? in
            let filter = CIFilter.areaAverage()
            filter.inputImage = ciImage
            filter.extent = rect
            guard let output = filter.outputImage else { return nil }

            var pixel = [UInt8](repeating: 0, count: 4)
            context.render(
                output,
                toBitmap: &pixel,
                rowBytes: 4,
                bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: nil
            )
            return NSColor(
                calibratedRed: CGFloat(pixel[0]) / 255.0,
                green: CGFloat(pixel[1]) / 255.0,
                blue: CGFloat(pixel[2]) / 255.0,
                alpha: 1.0
            )
        }
    }
}
#endif
