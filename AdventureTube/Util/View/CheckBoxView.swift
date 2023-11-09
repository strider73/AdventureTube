//
//  CheckBoxView.swift
//  AdventureVictoria
//
//  Created by chris Lee on 23/9/21.
//

import SwiftUI

struct CheckBoxView: View {
    @Binding var checked: Bool
    
    var body: some View {
        Image(systemName: checked ? "checkmark.square.fill" : "square")
            .foregroundColor(checked ? Color(UIColor.systemBlue) : Color.secondary)
            .onTapGesture {
                self.checked.toggle()
            }
            .padding(EdgeInsets(top: 5, leading: 25, bottom: 5, trailing: 5))
    }
}

struct CheckBoxView_Previews: PreviewProvider {
    struct CheckBoxViewHolder: View {
        @State var checked = false
        
        var body: some View {
            CheckBoxView(checked: $checked)
        }
    }
    static var previews: some View {
        CheckBoxViewHolder()
    }
}
