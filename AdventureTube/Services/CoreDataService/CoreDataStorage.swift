//
//  CoreDataStorage.swift
//  AdventureTube
//
//  Created by chris Lee on 2/5/22.
//https://www.donnywals.com/observing-changes-to-managed-objects-across-contexts-with-combine/

import Foundation
import CoreData
import Combine


class CoreDataStorage {
    
    //This will retrieve the managed object from persistent store and associate it with the target context
    func publisher<T: NSManagedObject>(for managedObject: T,
                                       in context: NSManagedObjectContext) -> AnyPublisher<T, Never> {
        
        //create notification from NSManagedObjectContext
        let notification = NSManagedObjectContext.didMergeChangesObjectIDsNotification
        
        return NotificationCenter.default.publisher(for: notification, //notification
                                                       object: context) //target context
        //grab the notification and check weather it has a list of updated managed objectID
            .compactMap({ notification in
                //NSManagedObjectID   uniquely identifies the same managed object
                //get list of updated managed object ID
                if let updated = notification.userInfo?[NSUpdatedObjectIDsKey] as? Set<NSManagedObjectID>,
                   
                    //check the target context objectID in the set
                   updated.contains(managedObject.objectID),
                   //if it contained pull the managed Object into the target context
                   let updatedObject = context.object(with: managedObject.objectID) as? T {
                    
                    //This whole process will retrieve the managed object from the persistent store
                    //and associated it with the target context
                    return updatedObject
                } else {
                    return nil
                }
            })
            .eraseToAnyPublisher()
    }
    
    func publisher<T: NSManagedObject>(for managedObject: T,
                                       in context: NSManagedObjectContext,
                                       //possible to listen for one or more kinds of changes
                                       changeTypes: [ChangeType]) ->
    //return tuple that contain the managed object
    //and change type triggered the publisher
    AnyPublisher<(object: T?, type: ChangeType), Never> {
        
        let notification = NSManagedObjectContext.didMergeChangesObjectIDsNotification
        return NotificationCenter.default.publisher(for: notification, object: context)
            .compactMap({ notification in
                for type in changeTypes {
                    if let object = self.managedObject(with: managedObject.objectID, changeType: type,
                                                       from: notification, in: context) as? T {
                        return (object, type)
                    }
                }
                
                return nil
            })
            .eraseToAnyPublisher()
    }
    
    
    
    func managedObject(with id: NSManagedObjectID,
                       changeType: ChangeType,
                       from notification: Notification,
                       in context: NSManagedObjectContext) -> NSManagedObject? {
            //get list of updated managed object ID
        guard let objects = notification.userInfo?[changeType.userInfoKey] as? Set<NSManagedObjectID>,
              //check the target context objectID in the set
              objects.contains(id) else {
                  return nil
              }
        
        return context.object(with: id)
    }
    
    ///take T rather than managed object instance  as first argument
    ///so by passing Album.self as a type AnyPublsher we create will retuen an array of ([T], changeType)
    ///since we can  have a multiple changes in a single notification and each change can have
    ///multiple managed object
    func didSavePublisher<T: NSManagedObject>(for type: T.Type,
                                       in context: NSManagedObjectContext,
                                       changeTypes: [ChangeType]) -> AnyPublisher<[([T], ChangeType)], Never> {
      
        //       let notification = NSManagedObjectContext.didMergeChangesObjectIDsNotification
        
//        let notification = NSManagedObjectContext.didSaveObjectsNotification
        let notification = NSManagedObjectContext.didSaveObjectIDsNotification


        return NotificationCenter.default.publisher(for: notification, object: context)
            .compactMap({ notification in
                // use  compactMap  to loop over all changes type that we observing
                return changeTypes.compactMap({ type -> ([T], ChangeType)? in
                    //in each changes check the Set for the targer managedObjectID
                    guard let changes = notification.userInfo?[type.userInfoKey] as? Set<NSManagedObjectID> else {
                        return nil
                    }
                    
                    //if yes extract only the managed object IDs that have an enity description
                    // that matches the observied type's entity description
                    let objects = changes
                        .filter({ objectID in objectID.entity == T.entity() })
                    //retrieve objects with found ids from target context
                    // and filtering all nil value if casting T failed
                        .compactMap({ objectID in context.object(with: objectID) as? T })
                    return (objects, type)
                })
            })
            .eraseToAnyPublisher()
    }
    
    
    enum ChangeType {
        case inserted, deleted, updated
        
        //computed property
        //to easily access the correct key in notification's userInfo dictionary
        var userInfoKey: String {
            switch self {
            case .inserted: return NSInsertedObjectIDsKey
            case .deleted: return NSDeletedObjectIDsKey
            case .updated: return NSUpdatedObjectIDsKey
            }
        }
    }



}

