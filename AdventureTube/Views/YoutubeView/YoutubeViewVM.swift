//https://github.com/SvenTiigi/YouTubePlayerKit
//https://github.com/SvenTiigi/YouTubePlayerKit/blob/main/Sources/API/YouTubePlayerAPI.swift
//  YoutubeViewVM.swift
//  AdventureTube
//
//  Created by chris Lee on 17/5/22.
//
//sdfsdfsdf

import Foundation
import YouTubePlayerKit
import Combine
import SwiftUI


class YoutubeViewVM : ObservableObject{
    @Published var isSearchMode = false
    @Published var youtubePlaysBackState : YouTubePlayer.PlaybackState = .unstarted
    @Published var currentTime : Int?
    
    @Published var startTime : Int = 0 {
        didSet {
            print("start time  is : \(startTime)")
            
            
            self.youTubePlayer.update(configuration: .init(//autoPlay: startTime > 0 ? true : false,
                autoPlay: true,
                showControls: true,
                startTime:  startTime))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                self.youTubePlayer.pause()
            }
            
        }
    }
    private let fileManager = LocalImageFileManager.instance
    private var cancellable : AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    var youTubePlayer : YouTubePlayer
    //youTubePlayer will update  when the strat time has been change
    /// Update YouTubePlayer Configuration
    /// - Note: Updating the Configuration will result in a reload of the entire YouTubePlayer
    /// - Parameter configuration: The YouTubePlayer Configuration
    
    var videoId  = ""
    var videoTitle = ""
    
    
    
    
    init(videoId : String , videoTitle : String = "" ,startTime : Int = 0){
        print("YoutubeViewVM  video id : \(videoId), videoTitle : \(videoTitle), start time : \(startTime)~~~~")
        
        self.videoId = videoId
        self.videoTitle = videoTitle
        self.startTime = startTime
        self.currentTime = startTime
        
        //initiate youtube player base on parameter
        self.youTubePlayer = YouTubePlayer(
            source: .video(id:"\(self.videoId)" ),
            configuration: .init(isUserInteractionEnabled: true ,
                                 autoPlay: startTime > 0 ? true : false,
                                 showControls: true,
                                 startTime:  startTime)
        )
        
        //listening  from YoutubePlayer
        setCurrentTimeByYoutubeTimePublisher()
        playbackStatePublisher()
    }
    
    func playbackStatePublisher(){
        youTubePlayer.playbackStatePublisher.sink { playsBackState in
            self.youtubePlaysBackState = playsBackState
            switch playsBackState {
                case .playing :
                    //syn slide bar
                    return print("playing")
                case .buffering :
                    return print("buffering")
                case .paused  :
                    return print("paused at \(self.currentTime)")
                case .ended   :
                    return print("ended")
                case .unstarted:
                    self.youTubePlayer.play()
                    return print("unstarted")
                case .cued:
                    return print("cued")
            }
        }
        .store(in: &cancellables)
        
    }
    
    
    func setCurrentTimeByYoutubeTimePublisher(){
        youTubePlayer.currentTimeAVTPublisher(updateInterval: 0.5).sink {[weak self] currentTime in
            if let self = self{
                //set the current time
                self.currentTime = Int(currentTime)
                //                self.syncSliderBarWithCurrentTimeWhenVideoPlay(currentTime: currentTime)
            }
        }
        .store(in: &cancellables)
    }
    
    
    func seek(){
        self.youTubePlayer.seek(to:60, allowSeekAhead: false)
    }
    
    func play(){
        self.youTubePlayer.play()
    }
    
    func pause(){
        self.youTubePlayer.pause()
    }
    
    func stop(){
        self.youTubePlayer.stop()
    }
    
    
    func getDisplayTime() -> String {
        return TimeToString.getDisplayTime(currentTime ?? 0)
    }
    
    func  advenceSecondToYoutubeTime( _ seconds: Int) -> String {
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        
        return  formatter.string(from: TimeInterval(seconds))!
        
    }
    
}

/// The filter of self.playbackStatePublisher was main reason that
/// currentTime was not publlished when the player is after being pasued
/// since filter has been comment out the current time will emit the value all  the time !!!!!!!
public extension YouTubePlayerPlaybackAPI where Self: YouTubePlayerEventAPI {
    
    /// A Publisher that emits the current elapsed time in seconds since the video started playing
    /// - Parameter updateInterval: The update TimeInterval in seconds to retrieve the current elapsed time. Default value `0.5`
    func currentTimeAVTPublisher(updateInterval: TimeInterval = 0.5) -> AnyPublisher<Double, Never> {
        Just(
            .init()
        )
        .append(
            Timer.publish(
                every: updateInterval,
                on: .main,
                in: .common
            )
            .autoconnect()
        )
        .flatMap { _ in
            self.playbackStatePublisher
            //.filter { $0 == .playing}
                .removeDuplicates()
        }
        .flatMap { _ in
            Future { [weak self] promise in
                self?.getCurrentTime { result in
                    //print("result \(result )")
                    guard case .success(let currentTime) = result else {
                        return
                    }
                    if(currentTime > 0 ){// this wil prevent publihsed 0 current time
                        promise(.success(currentTime))
                    }
                }
            }
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
    
}

