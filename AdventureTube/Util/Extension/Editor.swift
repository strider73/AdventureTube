//
//  Editor.swift
//  AdventureTube
//
//  Created by chris Lee on 7/4/22.
//

import Foundation
import SwiftUI

extension UIApplication {
    
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}
