//
//  OrderedArray.swift
//  AdventureTube
//
//  Created by chris Lee on 25/7/2022.
//

import Foundation
import Combine

@propertyWrapper
struct OrderedChapterArrayPublished{
    // initial value of property
    private var chapters : [AdventureTubeChapter] = []
    //Publisher that publish new value when it get a newValue
    private var publisher = PassthroughSubject<[AdventureTubeChapter],Never>()
    
    var wrappedValue : [AdventureTubeChapter] {
        get {return  chapters}
        set { chapters = newValue.sorted{$0.youtubeTime  < $1.youtubeTime}
            self.publisher.send(chapters)
        }
    }
    
    //allow us to access publisher using a $!!!!!
    var projectedValue: AnyPublisher<[AdventureTubeChapter],Never>{
        return self.publisher.eraseToAnyPublisher()
    }
}

