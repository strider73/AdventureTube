//
//  NavBarButton.swift
//  AdventureTube
//
//  Created by chris Lee on 27/3/22.
//

import Foundation
import SwiftUI

enum CustomNavBarButtonInfo:Equatable{
    static func == (lhs: CustomNavBarButtonInfo, rhs: CustomNavBarButtonInfo) -> Bool {
        return lhs.iconName == rhs.iconName
    }
    
  
    
    case empty
    case addNewStory(myStoryCommonDetailViewVM : MyStoryCommonDetailViewVM)
    case updateStory(myStoryCommonDetailViewVM : MyStoryCommonDetailViewVM)
    case refreshMyStoryList(myStoryListVM : MyStoryListViewVM)
    case back
    case checkUpdateBeforeBack(addStoryViewVM : AddStoryViewVM)
    case saveStory(addStoryViewVM: AddStoryViewVM)
    case uploadStory(addStoryViewVM:AddStoryViewVM)
    case saveUpdateChangeStory(addStoryViewVM:AddStoryViewVM)
    var iconName: String {
        switch self{
        case .empty : return "questionmark"
        case .back : return "chevron.backward.circle"
        case .checkUpdateBeforeBack : return "chevron.backward.circle"
        case .updateStory : return "goforward.plus"
        case .addNewStory : return  "plus.circle"
        case .refreshMyStoryList : return "arrow.clockwise.circle"
        case .saveStory : return "archivebox.circle"
        case .uploadStory : return "square.and.arrow.up.circle"
        case .saveUpdateChangeStory : return "square.and.arrow.down.on.square"

        }
    }
    
    var color : Color {
        switch self {
        case .empty : return Color.black
        case .updateStory: return Color.blue
        case .addNewStory : return Color.black
        case .refreshMyStoryList : return Color.black
        case .back : return Color.black
        case .checkUpdateBeforeBack : return Color.blue
        case .saveStory : return Color.black
        case .uploadStory : return Color.black
        case .saveUpdateChangeStory : return Color.red

        }
    }
    
    
//    var function : () -> () {
//        switch self{
//        case .addNewStory : return {
//            print("Add new story function ")
//            CustomNavLink(destination: AddStoryView()) {
//                EmptyView()
//            }
//        }
//
//        case .back : return {
//            // nothing to do
//        }
//        case .refreshMyStoryList : return {
//
//        }
//        }
//    }
    
    
}
