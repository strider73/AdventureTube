//
//  CustomNavBarView.swift
//  AdventureTube
//
//  Created by chris Lee on 16/2/22.
//

//This is custom design for navigation bar
//without content area


import SwiftUI

struct CustomNavBarView: View {
    
//    @EnvironmentObject private var myStoryListVM : MainStoryListViewModel
    @Environment(\.dismiss) var dismiss
    
    
    var title : String
    @Binding var buttons : [CustomNavBarButtonItem]

    
    
    var body : some View {
        VStack(spacing : 0){
            HStack{
                switch buttons.count {
                case 1 :
                    HStack{
                        getFirstButton()
                        Spacer()
                        titleSection
                        Spacer()
                        EmptyButton
                    }
                case 2 :
                    HStack{
                        getFirstButton()
                        Spacer()
                        titleSection
                        Spacer()
                        getLastButton()
                    }
                default :
                    HStack{
                        EmptyButton
                        Spacer()
                        titleSection
                        Spacer()
                        EmptyButton
                    }
                }
            }
            .padding(10)
        }
    }
    
}
  


extension CustomNavBarView {
    
    private func getFirstButton() -> some View {
        
        let  button = buttons.first!
        return returnButton(button: button)
    }
    
    private func getLastButton() -> some View {
        
        let  button = buttons.last!
        return returnButton(button: button)
    }
    
    
    private func returnButton(button : CustomNavBarButtonItem) -> some View {
        switch button  {
        case .back :
            return Button(action: {
                dismiss()
            }) {
                Image(systemName:button.iconName)
                    .resizable()
                    .customNavButton()
            }
            .withPressableStyle(scaledAmount: 0.5)
            .opacity(button.iconName == "questionmark" ? 0 : 1)
            
        case .addNewStory(let myStoryListVM) :
            return Button(action: {
                
                myStoryListVM.isShowAddStory.toggle()
            }) {
                Image(systemName:button.iconName)
                    .resizable()
                    .customNavButton()
            }
            .withPressableStyle(scaledAmount: 0.5)
            .opacity(button.iconName == "questionmark" ? 0 : 1)
        case .updateStory(myStoryCommonDetailViewVM: let myStoryListVM) :
            return Button(action: {
                myStoryListVM.isShowAddStory.toggle()
            }) {
                Image(systemName:button.iconName)
                    .resizable()
                    .customNavButton()
            }
            .withPressableStyle(scaledAmount: 0.5)
            .opacity(button.iconName == "questionmark" ? 0 : 1)
            
        case .refreshMyStoryList(let myStoryListVM)  :
            return Button(action: {
                myStoryListVM.isShowRefreshAlert.toggle()
            }) {
                Image(systemName:button.iconName)
                    .resizable()
                    .customNavButton()
                
            }
            .withPressableStyle(scaledAmount: 0.5)
            .opacity(button.iconName == "questionmark" ? 0 : 1)

            
        case .empty :
            return Button(action: {
                dismiss()
            }) {
                Image(systemName:button.iconName)
                    .resizable()
                    .customNavButton()
                
            }
            .withPressableStyle(scaledAmount: 0.5)
            .opacity(button.iconName == "questionmark" ? 0 : 1)
            
        case .checkUpdateBeforeBack(let addStoryViewVM):
            return Button(action: {
                dismiss()

            }) {
                Image(systemName:button.iconName)
                    .resizable()
                    .customNavButton()
                
            }
            .withPressableStyle(scaledAmount: 0.5)
            .opacity(button.iconName == "questionmark" ? 0 : 1)
        case .saveStory(let addStoryViewVM):
            return Button(action: {
                //addStoryViewVM.saveUpdatedStory()
//                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName:button.iconName)
                    .resizable()
                    .customNavButton()
                
            }
            .withPressableStyle(scaledAmount: 0.5)
            .opacity(button.iconName == "questionmark" ? 0 : 1)
            
        case .uploadStory(let addStoryViewVM):
            return Button(action: {
                addStoryViewVM.actionSheet = .uploadConfirmSheet
            }) {
                Image(systemName:button.iconName)
                    .resizable()
                    .customNavButton()
                
            }
            .withPressableStyle(scaledAmount: 0.5)
            .opacity(button.iconName == "questionmark" ? 0 : 1)
            
        case .saveUpdateChangeStory(let addStoryViewVM):
            return Button(action: {
     //           addStoryViewVM.saveUpdatedStory()
//                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName:button.iconName)
                    .resizable()
                    .customNavButton(color: button.color)
                
            }
            .withPressableStyle(scaledAmount: 0.5)
            .opacity(button.iconName == "questionmark" ? 0 : 1)
        
        }
        

        
        
        
    }
    private var titleSection : some View  {
        VStack{
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                .lineLimit(2)
        }
    }

    
    private var EmptyButton : some View {
        Button(action: {
        }) {
            Image(systemName: "plus.circle")
                .resizable()
                .customNavButton()
        }
        .opacity(0)
    }

}

struct CustomNavBarView_Previews: PreviewProvider {
  @State  static var buttons :[CustomNavBarButtonItem] = [
        .back , .addNewStory(myStoryCommonDetailViewVM: dev.myStoryCommonDetailViewVM)
    ]
    
    static var previews: some View {
        VStack{
            CustomNavBarView(title: "Title is here", buttons: $buttons )
            Spacer()
        }
    }
}


