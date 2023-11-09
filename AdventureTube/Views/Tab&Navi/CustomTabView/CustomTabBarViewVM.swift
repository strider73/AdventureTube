//
//  CustomTabViewModel.swift
//  AdventureTube
//
//  Created by chris Lee on 19/3/22.
//

import Foundation
import SwiftUI

class CustomTabBarViewVM :ObservableObject {
    @Published var isTabBarViewShow :Bool = true
    
    init(){
        print("init CustomTabBarViewModel")
    }
    
    func hideTabBar(){
            isTabBarViewShow = false
    }
    
    func showTabBar(){
            isTabBarViewShow = true
    }
}
