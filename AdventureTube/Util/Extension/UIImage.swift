//
//  UIImage.swift
//  AdventureTube
//
//  Created by chris Lee on 21/4/22.
//

import Foundation
import UIKit
import SwiftUI

public extension UIImage {
    //This one for solid color  image
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
      UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
          
      guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
      defer { UIGraphicsEndImageContext() }
          
      let rect = CGRect(origin: .zero, size: size)
      ctx.setFillColor(color.cgColor)
      ctx.fill(rect)
      ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
      ctx.draw(image, in: rect)
          
      return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
    
    func maskWithColor(color: UIColor) -> UIImage? {
         let maskImage = cgImage!

         let width = size.width
         let height = size.height
         let bounds = CGRect(x: 0, y: 0, width: width, height: height)

         let colorSpace = CGColorSpaceCreateDeviceRGB()
         let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
         let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!

         context.clip(to: bounds, mask: maskImage)
         context.setFillColor(color.cgColor)
         context.fill(bounds)

         if let cgImage = context.makeImage() {
             let coloredImage = UIImage(cgImage: cgImage)
             return coloredImage
         } else {
             return nil
         }
     }
    
    
    func resize(maxWidthHeight : Double)-> UIImage? {

            let actualHeight = Double(size.height)
            let actualWidth = Double(size.width)
            var maxWidth = 0.0
            var maxHeight = 0.0

            if actualWidth > actualHeight {
                maxWidth = maxWidthHeight
                let per = (100.0 * maxWidthHeight / actualWidth)
                maxHeight = (actualHeight * per) / 100.0
            }else{
                maxHeight = maxWidthHeight
                let per = (100.0 * maxWidthHeight / actualHeight)
                maxWidth = (actualWidth * per) / 100.0
            }

            let hasAlpha = true
            let scale: CGFloat = 0.0

            UIGraphicsBeginImageContextWithOptions(CGSize(width: maxWidth, height: maxHeight), !hasAlpha, scale)
            self.draw(in: CGRect(origin: .zero, size: CGSize(width: maxWidth, height: maxHeight)))

            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            return scaledImage
        }

}


extension UIImageView {
  func setImageColor(color: UIColor) {
    let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
    self.image = templateImage
    self.tintColor = color
  }
}
