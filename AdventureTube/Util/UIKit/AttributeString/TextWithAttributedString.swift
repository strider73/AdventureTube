//
//  TextWithAttributedString.swift
//  AdventureTube
//
//  Created by chris Lee on 12/4/22.
//

import Foundation
import SwiftUI


struct TextWithAttributedString : UIViewRepresentable {
    var attributedString : NSMutableAttributedString
    var preferredMaxLayoutWidth : CGFloat = 0
    @Binding var dynamicHeight: CGFloat // This is not using at this moment but could use later on 

    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        
        return label
        
    }
    
    
    func updateUIView(_ uiView: UILabel, context: UIViewRepresentableContext<TextWithAttributedString>) {
        uiView.attributedText = attributedString
        DispatchQueue.main.async {
                       dynamicHeight = uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
                   }
    }
}
