//
//  BindingExtention.swift
//  StudyProject
//
//  Created by chris Lee on 4/10/21.
//

import Foundation
import SwiftUI

/*
 Capturing a given value within a pair of getter and setter closures
 */
extension Binding{
    static func mock( _ value:Value)  -> Self{
        var value = value
        return Binding(get:{value},
                       set:{value = $0})
    }
}
