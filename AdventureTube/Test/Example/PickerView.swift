//
//  PickerView.swift
//  AdventureTube
//
//  Created by chris Lee on 31/3/22.
//

import SwiftUI

struct PickerView: View {
    @State var selectedNumber: Int = 0

    var body: some View {
        HStack {
            Text("what is your age ?")
                .padding(.horizontal)
            Menu {
                   Picker(selection: $selectedNumber, label: EmptyView()) {
                       ForEach(0..<10) {
                           Text("\($0)")
                       }
                   }
               } label: {
                   customLabel
           }
        }
        
    }
    
    var customLabel: some View {
        HStack {
            Image(systemName: "paperplane")
            Text(String(selectedNumber))
            Spacer()
            Text("⌵")
                .offset(y: -4)
        }
        .foregroundColor(.black)
        .font(.title)
        .padding()
        .frame(height: 32)
        .background(ZStack {
            Color.black
            Color.white
                .padding(1)
                .cornerRadius(14)
        })
        .cornerRadius(10)
    }
}

struct PickerView_Previews: PreviewProvider {
    static var previews: some View {
        PickerView()
    }
}
