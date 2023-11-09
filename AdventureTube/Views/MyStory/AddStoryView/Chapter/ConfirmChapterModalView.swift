//
//  ModalView.swift
//  AdventureTube
//
//  Created by chris Lee on 28/6/22.
//https://www.youtube.com/watch?v=I1fsl1wvsjY
import SwiftUI
import GoogleSignIn




struct ConfirmChapterModalView<Item : Identifiable ,Content:View>: View{
    @EnvironmentObject private var loginManager : LoginManager
    let content : Content?
    @Binding var isShowing:Bool
    @Binding var item : Item?
    @State private var isDragging = false
    
    @State private var curHeight:CGFloat
    let minHeight : CGFloat = 380
    let maxHeight : CGFloat = 750
    
    let startOpacity : Double = 0.4
    let endOpacity : Double = 0.8
    
    private var user: GIDGoogleUser? {
        return GIDSignIn.sharedInstance.currentUser
    }
    
    
    init(isShowing:Binding<Bool>, item :Binding<Item?> ,size : CurHeightType,@ViewBuilder content:@escaping (Item?) -> Content){
        self._isShowing = isShowing
        self._item = item
        self.content = content(item.wrappedValue)//This is very important
        _curHeight = State(initialValue: CGFloat(size.rawValue))
    }
    
    var dragPercentage: Double {
        let res = Double((curHeight - minHeight) / (maxHeight - minHeight))
        return max(0,min(1,res))
    }
    var body: some View {
        ZStack(alignment: .bottom) {
            if isShowing {
                Color.black
                    .opacity(startOpacity + (endOpacity - startOpacity) * dragPercentage)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isShowing = false
                    }
                
                mainView
                    .transition(.move(edge: .bottom))
            }
        }
        .frame(maxWidth:.infinity, maxHeight: .infinity , alignment: .bottom)
        .ignoresSafeArea()
        .animation(.easeInOut)
        
    }
    
    var mainView : some View {
        VStack{
            
            if let userProfile = user?.profile{
                ZStack{
                    UserProfileMediaumImageView(userProfile: userProfile)
                }
                .frame(height:40)
                .frame(maxWidth:.infinity)
                .background(Color.white.opacity(0.00001))
                .gesture(dragGesture)

            }
            
            //-->for UI test
//            ZStack{
//                Image("testProfileImage")
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: 88, height: 88, alignment: .center)
//                    .scaledToFit()
//                    .clipShape(Circle())
//            }
//            .frame(height:40)
//            .frame(maxWidth:.infinity)
//            .background(Color.white.opacity(0.00001))
//            .gesture(dragGesture)
            //<--for UI test

            // the actual content area
            ZStack{
                content
            }
            .frame(maxHeight:.infinity)
            .padding(.bottom, 30)
            //.background(Color.yellow)
        }
        .frame(height:curHeight)
        .frame(maxWidth:.infinity)
        .background(
            ZStack{
                RoundedRectangle(cornerRadius: 30)
                Rectangle()
                    .frame(height: curHeight / 2)
            }
                .foregroundColor(.white)
                .offset(y:5)
        )
        .animation(isDragging ? nil : .easeInOut(duration: 0.45))
    }
    
    
    @State private var prevDragTranslation = CGSize.zero
    
    var dragGesture : some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { val in
                if  !isDragging {
                    isDragging = true
                }
                let dragAmount = val.translation.height - prevDragTranslation.height
                if curHeight > maxHeight || curHeight < minHeight {
                    curHeight -= dragAmount / 6
                }else{
                    curHeight -= dragAmount
                }
                prevDragTranslation = val.translation
            }
            .onEnded { val in
                prevDragTranslation = .zero
                isDragging = false
                if curHeight > maxHeight {
                    curHeight = maxHeight
                }else if curHeight < maxHeight {
                    curHeight = minHeight
                }
            }
    }
}

struct ConfirmModalView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmChapterModalView(isShowing: .constant(true),
                  item: .constant(ConfirmChapterModalData(createChapterViewVM: dev.addStoryViewVM.createChapterViewVM)) ,
                  size: .small) { confirmChapterModalData in
            if let confirmChapterModalData = confirmChapterModalData {
                ConfirmChapterView(createChapterViewVM: confirmChapterModalData.createChapterViewVM, isShowing: .constant(true))
            }
        }
    }
}
