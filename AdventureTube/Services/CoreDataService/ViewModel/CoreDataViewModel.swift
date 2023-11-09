// Source code from "How to use Core Data with MVVM Architecture in SwiftUI| Continued Learning #15"
//  https://youtu.be/BPQkpxtgalY?si=B73-dwcMtyQmU1A9
//  CoreDataVioewModel.swift
//  AdventureTube
//
//  Created by chris Lee on 19/10/2023.
//

import Foundation
import CoreData


class CoreDataViewModel: ObservableObject {
    
    let container: NSPersistentContainer
    @Published var savedEntities : [StoryEntity] = []
    
    
    init(){
        container = NSPersistentContainer(name:"Adventuretube")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading core data. \(error)")
            }
        }
    }
    
    func fetchAdventureTubes(){
        let request  = NSFetchRequest<StoryEntity>(entityName: "StoryEntity")
        
        do{
            savedEntities = try container.viewContext.fetch(request)
        }catch let error {
            print("Error fewtching .\(error)")
        }
    }
    
    
    //from here we can make add,delete,update,list and search
    func addAdventureTubeStory(text:String){
        
    }
    
}
