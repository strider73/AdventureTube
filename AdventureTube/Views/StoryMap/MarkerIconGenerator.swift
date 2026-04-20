//
//  MarkerIconGenerator.swift
//  AdventureTube
//
//  Created on 2/3/2026.
//

import UIKit

/// Generates rounded-square YouTube thumbnail marker icons with category-colored borders and a pin pointer.
final class MarkerIconGenerator {

    private static let cornerRadius: CGFloat = 8

    // MARK: - Category Color Mapping

    static func color(for category: Category) -> UIColor {
        switch category {
        case .camping, .campfire:
            return UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)   // green
        case .hiking:
            return UIColor(red: 0.55, green: 0.35, blue: 0.17, alpha: 1.0) // brown
        case .swimming, .marine, .kayak, .surf, .scubadiving, .fishing:
            return UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)   // blue
        case .caravan, .driving, .navigation:
            return UIColor(red: 0.95, green: 0.55, blue: 0.15, alpha: 1.0) // orange
        case .cooking, .bbq:
            return UIColor(red: 0.9, green: 0.25, blue: 0.2, alpha: 1.0)  // red
        case .party, .beer, .music:
            return UIColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0)   // purple
        case .lookout:
            return UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)   // green
        case .mtb, .dirtbike:
            return UIColor(red: 0.55, green: 0.35, blue: 0.17, alpha: 1.0) // brown
        case .geocaching:
            return UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)   // green
        case .unknown:
            return .gray
        }
    }

    /// Resolves the primary color from an array of categories (uses first, falls back to gray).
    static func color(for categories: [Category]) -> UIColor {
        guard let primary = categories.first else { return .gray }
        return color(for: primary)
    }

    // MARK: - Marker Icon Generation

    /// Downloads a YouTube thumbnail and composites it into a rounded-square marker icon with a pin pointer and optional chapter number.
    static func generateMarkerIcon(
        thumbnailURL: URL,
        borderColor: UIColor,
        size: CGFloat = 50,
        chapterNumber: Int? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        URLSession.shared.dataTask(with: thumbnailURL) { data, _, error in
            guard let data = data, error == nil, let thumbnail = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let icon = compositeMarkerIcon(thumbnail: thumbnail, borderColor: borderColor, size: size, chapterNumber: chapterNumber)
            DispatchQueue.main.async { completion(icon) }
        }.resume()
    }

    /// Creates a placeholder marker icon (gray rounded square with pin) when no thumbnail is available yet.
    static func placeholderMarkerIcon(borderColor: UIColor, size: CGFloat = 50) -> UIImage {
        let borderWidth: CGFloat = 3
        let pointerHeight: CGFloat = 10
        let totalWidth = size + borderWidth * 2
        let totalHeight = size + borderWidth * 2 + pointerHeight

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight))
        return renderer.image { context in
            let ctx = context.cgContext
            let squareRect = CGRect(x: borderWidth, y: borderWidth, width: size, height: size)
            let path = UIBezierPath(roundedRect: squareRect, cornerRadius: cornerRadius)

            // Rounded square background
            ctx.setFillColor(UIColor.lightGray.cgColor)
            ctx.addPath(path.cgPath)
            ctx.fillPath()

            // Border
            ctx.setStrokeColor(borderColor.cgColor)
            ctx.setLineWidth(borderWidth)
            ctx.addPath(path.cgPath)
            ctx.strokePath()

            // Pin pointer triangle
            drawPointer(in: ctx, totalWidth: totalWidth, totalHeight: totalHeight,
                        topY: size + borderWidth * 2, color: borderColor)
        }
    }

    // MARK: - Compositing

    static func compositeMarkerIcon(
        thumbnail: UIImage,
        borderColor: UIColor,
        size: CGFloat = 50,
        chapterNumber: Int? = nil
    ) -> UIImage {
        let borderWidth: CGFloat = 3
        let pointerHeight: CGFloat = 10
        let totalWidth = size + borderWidth * 2
        let totalHeight = size + borderWidth * 2 + pointerHeight

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight))
        return renderer.image { context in
            let ctx = context.cgContext
            let squareRect = CGRect(x: borderWidth, y: borderWidth, width: size, height: size)
            let path = UIBezierPath(roundedRect: squareRect, cornerRadius: cornerRadius)

            // Clip thumbnail to rounded square
            ctx.saveGState()
            ctx.addPath(path.cgPath)
            ctx.clip()
            thumbnail.draw(in: squareRect)
            ctx.restoreGState()

            // Border
            ctx.setStrokeColor(borderColor.cgColor)
            ctx.setLineWidth(borderWidth)
            ctx.addPath(path.cgPath)
            ctx.strokePath()

            // Chapter number badge (top-left corner)
            if let number = chapterNumber {
                drawChapterBadge(in: ctx, number: number, borderColor: borderColor,
                                 origin: CGPoint(x: borderWidth, y: borderWidth))
            }

            // Pin pointer triangle
            drawPointer(in: ctx, totalWidth: totalWidth, totalHeight: totalHeight,
                        topY: size + borderWidth * 2, color: borderColor)
        }
    }

    private static func drawChapterBadge(in ctx: CGContext, number: Int, borderColor: UIColor,
                                          origin: CGPoint) {
        let badgeSize: CGFloat = 18
        let badgeRect = CGRect(x: origin.x, y: origin.y, width: badgeSize, height: badgeSize)

        // Circle background
        ctx.setFillColor(borderColor.cgColor)
        ctx.fillEllipse(in: badgeRect)

        // Number text
        let text = "\(number)" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.white
        ]
        let textSize = text.size(withAttributes: attributes)
        let textPoint = CGPoint(
            x: badgeRect.midX - textSize.width / 2,
            y: badgeRect.midY - textSize.height / 2
        )
        text.draw(at: textPoint, withAttributes: attributes)
    }

    private static func drawPointer(in ctx: CGContext, totalWidth: CGFloat, totalHeight: CGFloat,
                                     topY: CGFloat, color: UIColor) {
        let pointerTip = CGPoint(x: totalWidth / 2, y: totalHeight)
        let pointerLeft = CGPoint(x: totalWidth / 2 - 8, y: topY - 1)
        let pointerRight = CGPoint(x: totalWidth / 2 + 8, y: topY - 1)

        ctx.setFillColor(color.cgColor)
        ctx.beginPath()
        ctx.move(to: pointerLeft)
        ctx.addLine(to: pointerTip)
        ctx.addLine(to: pointerRight)
        ctx.closePath()
        ctx.fillPath()
    }
}
