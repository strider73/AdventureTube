//
//  DescriptionEditorView.swift
//  AdventureTube
//
//  Created by chris Lee on 26/3/22.
//

import SwiftUI

struct DescriptionEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var description : String
   
    var body : some View {
        
        VStack {
            TextEditor(text: $description)
                .submitLabel(.done)
                .onSubmit {
                    print("store data to coredata")
            }
                .padding(10)
            
            HStack{
                Button("cancel"){
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(width: 100, height: 50)
                .background(Color.gray)
                .clipped()
                .cornerRadius(10)
                .withPressableStyle()

                
                Button("submit"){
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(width: 100, height: 50)
                .background(Color.gray)
                .clipped()
                .cornerRadius(10)
                .withPressableStyle()
            }
        }
    }
}


struct DescriptionEditorView_Previews: PreviewProvider {
    static var previews: some View {
        DescriptionEditorView(description: .constant("test String "))
    }
}
