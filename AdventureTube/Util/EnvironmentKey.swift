//
//  EnvironmentKey.swift
//  AdventureTube
//
//  Created by chris Lee on 5/2/22.
//

import Foundation
import SwiftUI

/*
 Create the new Kye MyTubeBackGroundColor by conform EnvironmentKey Protocol
 which is create the default value for new environment key
 
 */
private  struct MyTubeBackgroundColor : EnvironmentKey{
    static let defaultValue =  Color(.secondarySystemBackground)
}

/*
 adding the key to the EnviromentValues , we just create  by using a extention
 and providing getter/setter in order to access custom key we just made
 
 
 after this extention myTubeBackgroudColor is ready as normal @Environment
 
 */

extension EnvironmentValues {
    //computed property
    var  myTubeBackgroundColor : Color {
        get{( self[MyTubeBackgroundColor.self])}
        set{( self[MyTubeBackgroundColor.self] = newValue)}
    }
}



