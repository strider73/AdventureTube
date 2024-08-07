//
//  CustonTextFieldDropDownList.swift
//  AdventureTube
//
//  Created by chris Lee on 14/4/22.
//

import SwiftUI


struct CustonTextFieldDropDownList: View{
    @State var value = ""
    var placeholder = "Select Client"
    var dropDownList = ["PSO", "PFA", "AIR", "HOT"]
    var body: some View {
        Menu {
            ForEach(dropDownList, id: \.self){ client in
                Button(client) {
                    self.value = client
                }
            }
        } label: {
            VStack(spacing: 5){
                HStack{
                    Text(value.isEmpty ? placeholder : value)
                        .foregroundColor(value.isEmpty ? .gray : .black)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color.orange)
                        .font(Font.system(size: 20, weight: .bold))
                }
                .padding(.horizontal)
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 2)
            }
        }
    }
}


struct CustonTextFieldDropDownList_Previews: PreviewProvider {
    static var previews: some View {
        CustonTextFieldDropDownList()
    }
}
