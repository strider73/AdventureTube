//
//  AdventureTubeApp.swift
//  AdventureTube
//
//  Created by chris Lee on 16/12/21.
//
import SwiftUI
import GoogleSignIn




@main
struct AdventureTubeApp: App {
    //    In Order to using appDelegation
    //    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    //    let persistenceController = PersistenceController.shared
    
    // initializae SettingViewModel and store as environmentObject
    //TODO: loginManager has to be ready for other social Login Service
    @UIApplicationDelegateAdaptor(AdventureTubeAppDelegate.self) var appDelegate
    @StateObject private var loginManager : LoginManager = LoginManager.shared
    @StateObject private var customTabVM : CustomTabBarViewVM = CustomTabBarViewVM.shared

    
    /*
     Core Data Setting
     
     Make sure that the environment where the manage object context is stored knows about
     our current NSManagedObjectContext
     
     .environment(\.managedObjectContext, persistenceController.container.viewContext)
     */
    
    
    
    var body: some Scene {
        WindowGroup {
                HomeView()
                    //.navigationBarBackButtonHidden(true) will be on each view that is needed ex) loginView , MyStoryListView
//                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(loginManager)
                    .environmentObject(customTabVM)
        }
    }
    
    
}

