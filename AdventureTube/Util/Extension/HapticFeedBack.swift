//
//  HapticFeedBAck.swift
//  AdventureTube
//
//  Created by chris Lee on 20/4/22.
//

import Foundation
import SwiftUI

//This function is only working on View Not a button since onTapGesture is not working on button
extension View {

  func hapticImpactFeedbackOnTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .heavy) -> some View {
    self.onTapGesture {
      let impact = UIImpactFeedbackGenerator(style: style)
      impact.impactOccurred()
    }
  }
    
    func hapticNotificationFeedbackOnTap(style: UINotificationFeedbackGenerator.FeedbackType = .success) -> some View {
      self.onTapGesture {
        let notification = UINotificationFeedbackGenerator()
          notification.notificationOccurred(style)
      }
}

    
//    func hapticFeedbackOnTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .heavy) -> some View {
//      self.onTapGesture {
//        let impact = UIImpactFeedbackGenerator(style: style)
//        impact.impactOccurred()
//      }
//    }
}
