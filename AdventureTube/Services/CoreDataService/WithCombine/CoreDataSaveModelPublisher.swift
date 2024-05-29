//
//  CoreDataSaveModelPublisher.swift
//  AdventureTube
//
//  Created by chris Lee on 2/5/22.
//https://medium.com/swlh/ios-core-data-with-combine-c80373c5484

import Foundation
import Combine
import CoreData
typealias Action = (()->())


struct CoreDataSaveModelPublisher : Publisher {
    //process success indicator
    typealias Output = Bool
    //Failure type
    typealias Failure = NSError
    
    //action closure to hold all the creation of the enitties
    private let action  : Action
    //use context to save entity
    private let context : NSManagedObjectContext
    
    
    init(action: @escaping Action, context: NSManagedObjectContext) {
        self.action = action
        self.context = context
    }
    
    
    //create custom Subscriber class which will do most of joab and pass the
    //all the properties use it for later
    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        let subscription = Subscription(subscriber: subscriber, context: context, action: action)
        subscriber.receive(subscription: subscription)
    }
    
    
}
//create subscription class and extended Subscription protocol
extension CoreDataSaveModelPublisher {
    class Subscription<S> where S : Subscriber, Failure == S.Failure, Output == S.Input {
        
        private var subscriber: S?
        private let action: Action
        private let context: NSManagedObjectContext
        
        init(subscriber: S, context: NSManagedObjectContext, action: @escaping Action) {
            self.subscriber = subscriber
            self.context = context
            self.action = action
        }
    }
}

//Save entity in to the CoreData
extension CoreDataSaveModelPublisher.Subscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        var demand = demand
        guard let subscriber = subscriber, demand > 0 else { return }
        
        do {
            action()
            demand -= 1
            try context.save()
            demand += subscriber.receive(true)
        } catch {
            subscriber.receive(completion: .failure(error as CoreDataSaveModelPublisher.Failure))
        }
    }
}

extension CoreDataSaveModelPublisher.Subscription: Cancellable {
    func cancel() {
        subscriber = nil
    }
}
