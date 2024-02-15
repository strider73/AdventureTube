//
//  TabBarItem.swift
//  AdventureTube
//
//  Created by chris Lee on 11/2/22.
//

import Foundation
import SwiftUI

enum TabBarItemInfoEnum : String , Hashable ,Identifiable {
    var id: String {return self.rawValue}
    
    case storymap  , mystory , savedstory , setting
    
    var iconName : String {
        switch self {
        case .storymap  : return "map"
        case .mystory : return "list.and.film"
        case .savedstory : return "square.and.arrow.down"
        case .setting : return "gear"
        }
    }
    
    var title : String {
        switch self {
        case .storymap  : return "Story Map"
        case .mystory : return "My Stories"
        case .savedstory : return "Saved Story"
        case .setting : return "Setting"
        }
    }
    
    var color : Color {
        switch self {
        case .storymap  : return  Color.black
        case .mystory : return Color.black
        case .savedstory : return Color.black
        case .setting: return Color.black
        }
    }
}
