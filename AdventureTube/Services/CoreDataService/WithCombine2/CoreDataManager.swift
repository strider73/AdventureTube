//  Originate  https://youtu.be/huRKU-TAD3g
//    Core Data relationships, predicates, and delete rules in Xcode | Continued Learning #16
//  CoreDataManager.swift
//  AdventureTube
//
//  Created by chris Lee on 2/5/22.
//

import Foundation
import CoreData

class CoreDataManager{
    static let instance = CoreDataManager()
    let container : NSPersistentContainer
    let context : NSManagedObjectContext
    
    init(){
        //get the container
        container = NSPersistentContainer(name: "AdventureTube")
        
        //loading PersistentStores
        container.loadPersistentStores { description, error  in
            if let error = error {
                print("Error loading coredata. \(error) ")
            }
        }
        //access viewConext
        context = container.viewContext
        
        
        //it will merge changes that occured on a backgroud context
        //into view context automatically
        context.automaticallyMergesChangesFromParent = true
    }
    
    func save(){
        do {
            try context.save()
            print("core data saved successfully!!!!")
        }catch let error {
            print("Error saving Core Data.   \(error.localizedDescription)")
        }
    }
}

