//
//  CustomTextFieldView.swift
//  AdventureVictoria
//
//  Created by chris Lee on 23/9/21.
//

import SwiftUI

struct CustomTextFieldView: View {
    // Constants, so all "TextFields will be the same in the app"
    let fontsize: CGFloat = 20
    let backgroundColor = Color.white
    let textColor = Color.black
    
    // The @State Object
    @Binding var field: String
    // A custom variable for a "TextField"
    @State var isHighlighted = false
    var isSecureField = false
    
    var body: some View {
        if isSecureField {
            SecureField(field, text: $field)
                .font(Font.system(size: fontsize))
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray, lineWidth: 1))
                .background(RoundedRectangle(cornerRadius: 10).fill(backgroundColor))
                .foregroundColor(textColor)
                .padding(EdgeInsets(top: 5, leading: 25, bottom: 5, trailing: 25))
        }else{
            TextField(field, text: $field)
                .font(Font.system(size: fontsize))
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray, lineWidth: 1))
                .background(RoundedRectangle(cornerRadius: 10).fill(backgroundColor))
                .foregroundColor(textColor)
                .padding(EdgeInsets(top: 5, leading: 25, bottom: 5, trailing: 25))
        }
    }
}

struct CustomTextFieldView_Previews: PreviewProvider {
    @State static var name = "Chris Lee"

    static var previews: some View {
        CustomTextFieldView(field: $name, isHighlighted: true ,isSecureField: true)
        
    }
}

