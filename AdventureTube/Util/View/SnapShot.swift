//
//  SnapShot.swift
//  AdventureTube
//
//  Created by chris Lee on 28/6/22.
//

import Foundation
import SwiftUI
extension View {
    func snapshot() -> UIImage {
       // let controller = UIHostingController(rootView: self)
        let controller = UIHostingController(rootView: self.edgesIgnoringSafeArea(.all))

        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
