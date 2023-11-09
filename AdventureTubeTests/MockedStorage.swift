//
//  MockedStorage.swift
//  AdventureTubeTests
//
//  Created by chris Lee on 26/7/2022.
// original reference from Adding a Test Suit
//(https://betterprogramming.pub/how-to-create-a-property-wrapper-to-combine-storing-and-publishing-values-578c1c6bee88)

import Foundation
@testable import AdventureTube


/**
 using a Storage protocol we can esaily mocking fake storage
 using a Dictionary with is memory in this case 
 */
class MockStrage:Storage{
    //This is mock storage
    var memory: [String?:Any?] = [:]
    
    func string(forKey key: String) -> String? {
        memory[key] as? String
    }
    
    func set(_ value: String?, forKey key: String) {
        memory[key] = value
    }
}
