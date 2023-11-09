//
//  Array.swift
//  AdventureTube
//
//  Created by chris Lee on 25/7/2022.
//https://www.hackingwithswift.com/example-code/language/how-to-remove-duplicate-items-from-an-array

import Foundation
extension Array where Element : Hashable {
    //1) it will return !!!! after  duplicates are  removed
    func removingDuplicates() -> [Element]{
        var addedDict = [Element : Bool]()
        
        return filter {//This is Array.filter method
            
            //when you call updateValue() on a dictionary it returns nil if the key is new,
            //so we can use that to figure out which items are unique.
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    
    //2) place change to self
    mutating func removeDuplicates() {
           self = self.removingDuplicates()
    }
}
