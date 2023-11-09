//
//  UserDefaultPublisher.swift
//  AdventureTube
//
//  Created by chris Lee on 26/7/2022.
//  original reference(https://betterprogramming.pub/how-to-create-a-property-wrapper-to-combine-storing-and-publishing-values-578c1c6bee88)

import Foundation
import Combine
/**
    interface of any storage that only able to store String type
     it can be generic to store any kind .
 */
protocol  Storage {
    func string(forKey : String) -> String?
    func set(_ value : String? , forKey key: String)
}
/**
  make UserDefault to confirm Storage protocol  in order to use in
   UserPreferenceManager which is using storage only confirm Storage protocol
 */

extension UserDefaults : Storage {
    /**
     - parameters:
      - value : The actual value will be stored
      - key : key to retrieve  the value back
         
     */
    func set(_ value: String?, forKey key: String) {
        self.setValue(value , forKey: key)
    }

}
// MARK: - UserPrefereces class

class  UserPreferenceManager{
    enum StorageKeys: String {
        case name
    }
    
    private let storage : Storage
    
    /**
         new value will be store and published  when value of name is about to change 
     */
//    @Published var name: String?{
//        willSet{
//            self.storage.set(newValue, forKey: StorageKeys.name.rawValue)
//        }
//    }
    @StoredPublished(key:StorageKeys.name.rawValue)  var name:String?
    
    init(storage: Storage = UserDefaults.standard){
        self.storage = storage
        //This will bring the name value from the storage using a string function
        //self.name = self.storage.string(forKey: StorageKeys.name.rawValue)
        self._name.storage = self.storage
    }
    
    /**
     try to solve scalability issue using MirrorAPI top set the storage to all the type
      that are anotated withj the StoredPublished property wrapper
     */
    
//    func setupStorage( _ storage:Storage, for instance : Any){
//        let mirror = Mirror(reflecting: instance)
//
//        mirror.children.forEach { element in
//            guard let storedPublisher = element.value as? StoredPublished else {
//                return
//            }
//            storedPublisher.storage = storage
//        }
//    }
}


@propertyWrapper
struct StoredPublished {
    //implicitly unwrapped to support property injection
    var storage: Storage!
    var key: String
    //Support a send method
    private var publisher  = PassthroughSubject<String?,Never>()
    
    var wrappedValue : String? {
        get{
            return self.storage.string(forKey: key)
        }
        
        set {
            self.storage.set(newValue, forKey: self.key)
            self.publisher.send(newValue)
        }
    }
    
    //projected value which allow us to access published value
    //using $ Syntax withmeet
    var projectedValue : AnyPublisher<String?, Never>{
        return self.publisher.eraseToAnyPublisher()
    }

    
    init(key:String){
        self.key = key
    }
}
