//
//  TimeToString.swift
//  AdventureTube
//
//  Created by chris Lee on 12/7/2022.
//

import Foundation


struct TimeToString {
    
   public static func getDisplayTime(_ currentTime : Int ) -> String {
        return secondsToMinSec(currentTime)
    }
    
    public static func getYoutubeTime(_ currentTime : Int ) -> String {
         return secondToYoutubeTime(currentTime)
     }
    
   private static func  secondsToMinSec( _ seconds: Int) -> String {
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        
        return  formatter.string(from: TimeInterval(seconds))!
        
    }
    
    private static func  secondToYoutubeTime( _ seconds: Int) -> String {
         
         let formatter = DateComponentsFormatter()
         formatter.allowedUnits = [.hour, .minute, .second]
         formatter.unitsStyle = .positional
         
         return  formatter.string(from: TimeInterval(seconds))!
         
     }
    
}
