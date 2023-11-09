//
//  UIResponder.swift
//  AdventureTube
//
//  Created by chris Lee on 6/7/2022.
//https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/#:~:text=Moving%20SwiftUI%20View%20Up%20When%20Keyboard%20Appears&text=SwiftUI%20will%20automatically%20update%20the,emitted%20by%20the%20keyboardHeight%20publisher.

import Foundation
import UIKit


//This will detect a focused text input field using the good old UIKit
extension UIResponder {
    static var currentFirstResponder: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }

    private static weak var _currentFirstResponder: UIResponder?

    @objc private func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }

    // this will calcurate the responder frame in the global coodinate space 
    var globalFrame: CGRect? {
        guard let view = self as? UIView else { return nil }
        return view.superview?.convert(view.frame, to: nil)
    }
}
