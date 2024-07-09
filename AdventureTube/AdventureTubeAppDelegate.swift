//
//  AdventureTubeAppDelegate.swift
//  AdventureTube
//
//  Created by chris Lee on 9/7/2024.
//

import Foundation
import UIKit

class AdventureTubeAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        print("Custom initialization using app delegate")
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App is about to foreground")

    }
    func applicationWillTerminate(_ application: UIApplication) {
        // Perform any final clean-up tasks
        saveUserState()
        print("App is about to terminate")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Release shared resources, save user data, invalidate timers, etc.
        saveUserState()
        print("App entered background")
    }
    
    private func saveUserState(){
        let userDefaults = UserDefaults.standard
        do {
            try userDefaults.setObject(LoginManager.shared.publicUserData, forKey: "user")
            print("User data has been saved to UserDefault")
        }catch{
            print(error.localizedDescription)
        }
    }
}
