//
//  ExampleViewForNavigartionBar.swift
//  AdventureTube
//
//  Created by chris Lee on 27/3/22.
//

import SwiftUI

struct ExampleViewForNavigartionBar: View {
    var body: some View {
        NavigationView{
          Text("Hello, World!")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Test1"){
                            print("Test1")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Test1"){
                            print("Test2")
                        }
                    }
//                    ToolbarItemGroup() {
//                        Button("Test1"){
//                            print("test1")
//                        }
//                        Button("Test2"){
//                            print("test2")
//                        }
//                    }
                }
        }
    }
}

struct ExampleViewForNavigartionBar_Previews: PreviewProvider {
    static var previews: some View {
        ExampleViewForNavigartionBar()
    }
}
