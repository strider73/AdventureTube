//
//  introView.swift
//  AdventureTube
//
//  Created by chris Lee on 22/12/21.
//
// commit and push testing
import SwiftUI

struct HomeView: View {
  @EnvironmentObject private var loginManager : LoginManager
    let data = [1,2,3,4]
    
    var body: some View {
        // if user signed in send user tio contentView
        
        switch loginManager.publicLoginState{
        case .signedIn , .signedOut :
              AdventureTubeTabBarView()
        case .initial :
            PagerViewWithDots(data) { value in
                switch value {
                case 1 :
                    ExplainViewNo1()
                case 2 :
                    ExplainViewNo2()
                case 3 :
                    ExplainViewNo3()
                default:
                    ExplainViewNo4()
                }
            }
        }
    }
}
 
struct IntroView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            HomeView()
        }
        .environmentObject(dev.loginManager)
    }
}
