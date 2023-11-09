//
//  PagerViewWithDots.swift
//  Momentale
//
//  Created by chris Lee on 1/10/21.
//

import SwiftUI
/* by Chris
 
 @View Builder with Generic Content Parameter
 
 in here we gave the view generic parameter confirming to view
 ( which is restrict the return type using a generics !!!!!)
 and use the @ViewBuilder modifier to allow us to pass in a @ViewBuilder closure
 in order to create PageView which is nested View inside PagerViewWithDots
 
 What is BENEFICIAL  of using a @Viewbuilder ?????
 1)  convenient DSL syntax
 2) allow to use conditional flow like if or switcxh
 
 
 */
struct PagerViewWithDots<Data, Content>: View
where Data : RandomAccessCollection, Data.Element : Hashable, Content : View {
    @State private var currentIndex = 0
    
    private let data: Data
    
    // maps data to page views
    private let content: (Data.Element) -> Content
    /*
     Genereally
     uses @ViewBuilder to allow for convenient DSL syntax
     But in here  what the ViewBuilder doing is simply support conditional control flow
     by switch
     */
    init(_ data: Data,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
    
    var body: some View {
        //NavigationLink for ExplainViewNo4
        ZStack {
            
            Image("startPage_Background")
                .resizable()
                .edgesIgnoringSafeArea(.all)
                .blur(radius: currentIndex > 0 ? 5 : 0  )
            
            Image("appIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width:146)
                .offset(y:-280)
                .blur(radius: currentIndex > 0 ? 5 : 0  )
            
            
            // let the PagerView and the dots fill the available screen
            //Rectangle().foregroundColor(.black)
            // render the Pager View
            PagerView(data, currentIndex: $currentIndex, content: content)
            // the dots view
            VStack {
                Spacer() // align the dots at the bottom
                HStack(spacing: 33) {
                    ForEach(0..<data.count) { index in
                        Circle()
                            .foregroundColor((index == currentIndex) ? .red : .gray)
                            .frame(width: 12, height: 12)
                            .offset(y:-50)
                    }
                }
                
            }.padding()
        }
        
    }
}

struct PagerViewWithDots_Previews: PreviewProvider {
    
    
    static let data = [1,2,3,4]
    static var previews: some View {
        PagerViewWithDots(data) { number in
            /*
             @ViewBuilder also support condiotional control flow like
             if or switch
             */
            
            switch number {
            case 1 :
                ExplainViewNo1()
            case 2 :
                ExplainViewNo2()
            case 3 :
                ExplainViewNo3()
            default:
                ExplainViewNo4()
            }
            
        }
    }
}
