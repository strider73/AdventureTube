//
//  ProfileView.swift
//  AdventureTube
//
//  Created by chris Lee on 2/6/2023.
//

import SwiftUI

struct ProfileView: View {
    let columes:[GridItem] = [
        GridItem(.flexible(),spacing: nil, alignment: nil),
        GridItem(.flexible(),spacing: nil, alignment: nil),
        GridItem(.flexible(),spacing: nil, alignment: nil)
    ]
    
    var body: some View {
        
        ScrollView{
            Rectangle()
                .fill(Color.orange)
                .frame(height:400)
                .padding()
            
            LazyVGrid(columns: columes,
                      alignment: .center,
                      spacing: nil,
                      pinnedViews: [.sectionHeaders],
                      content: {
                
                
                Section(header:
                            Text("Section 1")
                    .foregroundColor(.white)
                    .font(.title )
                    .frame(maxWidth:.infinity , alignment: .leading)
                    .background(Color.blue)
                    .padding()
                        
                )
                {
                    
                    ForEach(0..<20){index in
                        Rectangle()
                            .frame(height:150)
                    }
                }
                
                
                Section(header:
                            Text("Section 2")
                    .foregroundColor(.white)
                    .font(.title )
                    .frame(maxWidth:.infinity , alignment: .leading)
                    .background(Color.red)
                    .padding()
                        
                )
                {
                    
                    ForEach(0..<20){index in
                        Rectangle()
                            .frame(height:150)
                    }
                }
            })
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
