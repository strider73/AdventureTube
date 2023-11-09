//
//  KeyboardPublisher.swift
//  AdventureTube
//
//  Created by chris Lee on 6/7/2022.
//https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/#:~:text=Moving%20SwiftUI%20View%20Up%20When%20Keyboard%20Appears&text=SwiftUI%20will%20automatically%20update%20the,emitted%20by%20the%20keyboardHeight%20publisher.

import Foundation
import Combine
import UIKit
import SwiftUI

extension Publishers {
    // 1.
//    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
//        // 2.
//        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
//            .map { $0.keyboardHeight }
//        
//        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
//            .map { _ in CGFloat(0) }
//        
//        // 3.Combine multiple publishers into one by merging their emitted values.
//        return MergeMany(willShow, willHide)
//            .eraseToAnyPublisher()
//    }
}
