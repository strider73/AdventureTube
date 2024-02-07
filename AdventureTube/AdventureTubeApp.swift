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
    @StateObject private var loginManager : LoginManager = LoginManager()
    @StateObject private var customTabVM : CustomTabBarViewVM = CustomTabBarViewVM()

    
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


//// Add this class  For Google Sign-In AppDelegation
//class AppDelegate: NSObject, UIApplicationDelegate {
//
//
//    //Used for attempting to restore user's sign-in state
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//
//        print(" application didFinishLaunching start")
//        //call restorePreviousSignIn to try and restore the sign-in state of users who already signed in using Google.
//        // in online
//        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
//            if error != nil || user == nil {
//
//            } else {
//
//
//                // Show the app's signed-in state.
//
////                guard let user = user else { return }
////
////                let emailAddress = user.profile?.email ?? "NoEamil"
////                let fullName = user.profile?.name ?? "No Name"
////                let givenName = user.profile?.givenName ?? "No Given Name"
////                let familyName = user.profile?.familyName ?? "No Family Name"
////                let profilePicUrl = user.profile?.imageURL(withDimension: 320) ?? URL(string: "No image URL")
////
////                let setting  = SettingModel(signed_in: true,
////                                           emailAddress: emailAddress,
////                                           fullName: fullName,
////                                           givenName: givenName,
////                                           familyName: familyName,
////                                           profilePicUrl: profilePicUrl?.absoluteString)
////                //Store data in environmentObject
//////                settingManager.setting = setting
////                //Store data in UserDefaukt
////                // Store Data in UserDefault
////                let userDefaults = UserDefaults.standard
////                do {
////                    try userDefaults.setObject(setting, forKey: "setting")
////                } catch {
////                    print(error.localizedDescription)
////                }
////
////                print("user is signed in state restored")
//
//            }
//        }
//        return true
//    }
//
//    //Used after Google Sign In
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        print("Initial Google Signed in Start")
//
//        // add this function for Google Sign in to handle the url
//
//        var handled: Bool
//        //Its ready to handle other Sign_In
//
//        handled = GIDSignIn.sharedInstance.handle(url)
//        if handled {
//            print("Google Signed in Success")
//
//            //redirect to profile
//            return true
//        }
//
//        // Handle other custom URL types.
//        // If not handled by this app, return false.
//
//        return false
//    }
//
//
//
//}


//class SceneDelegate: UIResponder, UIWindowSceneDelegate {
//    var window: UIWindow?
//    
//    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//        let contentView = ContentView()
//        // Use a UIHostingController as window root view controller.
//        if let windowScene = scene as? UIWindowScene {
//            let window = UIWindow(windowScene: windowScene)
//            window.rootViewController = UIHostingController(rootView: contentView)
//            self.window = window
//            window.makeKeyAndVisible()
//        }
//    }
//}
