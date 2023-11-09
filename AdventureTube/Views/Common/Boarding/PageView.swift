import SwiftUI

//
//  PageView.swift
//  Momentale
//
//  Created by chris Lee on 1/10/21.
//
struct PagerView<Data, Content>: View
where Data : RandomAccessCollection, Data.Element : Hashable, Content : View {
    private let data: Data
    // the index currently displayed page
    @Binding var currentIndex: Int
    // maps data to page views
    private let content: (Data.Element) -> Content
    
    // keeps track of how much did user swipe left or right
    @GestureState private var dragAmount: CGFloat = 0
    
    // the custom init is here to allow for @ViewBuilder for
    // defining content mapping
    init(_ data: Data,
         currentIndex: Binding<Int>,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        _currentIndex = currentIndex
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            LazyHStack(spacing: 0) {
                /*
                 render all the content, making sure that each page fills
                 the entire PagerView
                */
                ForEach(data, id: \.self) { elem in
                    content(elem)
                        .frame(width: geometry.size.width , height: geometry.size.height)
                        .foregroundColor(.white)
                    
//                    let _ = print("width : \(geometry.size.width)")
//                    let _ = print("height: \(geometry.size.height)")

                }
            }
            .frame(height: geometry.size.height, alignment: .center)
            // the first offset determines which page is shown
            .offset(x: -CGFloat(currentIndex) * geometry.size.width)
            // the second offset translates the page based on swipe
            .offset(x: dragAmount)
            .animation(.interactiveSpring())
            .gesture(
                /*
                 create the new drag gesture
                 aking it to modify the value stored in dragAmount
                 
                 took 3 parameter
                   value : current data for the drag
                            where it started , how far it's moved where it's predicted to end ... etc
                 
                   state : rather than reading or writing dragAmount directly
                           inside this closure we should modifty state
                 
                   transaction : store the whole animation context   which is continous or transient animation
                 
                 to make view draggable need to assign the current  transalation the drag straight to state.
                 */
                DragGesture().updating($dragAmount) { value, state, _ in
                    state = value.translation.width
                }.onEnded { value in
                    // determine how much was the page swiped to decide if the current page
                    // should change (and if it's going to be to the left or right)
                    // 1.25 is the parameter that defines how much does the user need to swipe
                    // for the page to change. 1.0 would require swiping all the way to the edge
                    // of the screen to change the page.
                    let offset = value.translation.width / geometry.size.width * 1.25
                    let newIndex = (CGFloat(currentIndex) - offset).rounded()
                    currentIndex = min(max(Int(newIndex), 0), data.count - 1)
                }
            )
        }
    }
}
struct PageView_Previews: PreviewProvider {
    // the source data to render, can be a range, an array, or any other collection of Hashable
    static let data = [1,2,3,4]
    // the index currently displayed page
    static var currentIndex: Int = 2
    // maps data to page views
    //private let content: (Data.Element) -> Content
    
    static var previews: some View {
        
        PagerView(data, currentIndex: .mock(currentIndex)) {
            pageNumber in
            switch pageNumber {
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
