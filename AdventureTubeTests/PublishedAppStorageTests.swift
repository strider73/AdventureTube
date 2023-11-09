//
//  PublishedAppStorageTests.swift
//  AdventureTubeTests
//
//  Created by chris Lee on 26/7/2022.
//

import XCTest
import Combine
@testable import AdventureTube

class PublishedAppStorageTests: XCTestCase {
    
    var storage : Storage!
    var cancellables : Set<AnyCancellable>!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.cancellables = []
        self.storage = MockStrage()
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        self.cancellables = nil
        self.storage = nil
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func test_content_publishValues(){
        let sut = UserPreferenceManager(storage: self.storage)
        sut.$name
            .dropFirst()// need to drop for the value is emitted after init which I believe it is nil!!
            .sink { text in
                XCTAssertEqual(text, "new stuff!")
            }
            .store(in: &cancellables)
        
        sut.name = "new stuff!"
    }
    
    func test_AppStorage_saveItems(){
        let sut = UserPreferenceManager(storage: self.storage)
        XCTAssertNil(storage.string(forKey:"name"))
        sut.name = "hello"
        XCTAssertEqual(storage.string(forKey: "name"),"hello")
    }
    
    func test_appStorage_startsWithTheRightItem(){
        self.storage.set("hey", forKey: "name")
        XCTAssertEqual(storage.string(forKey: "name"), "hey")
        
        let sut = UserPreferenceManager(storage: self.storage)
        XCTAssertEqual(sut.name , "hey")
     }

}
