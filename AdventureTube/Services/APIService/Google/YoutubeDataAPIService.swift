//
//  YoutubeDataAPService.swift
//  AdventureTube
//
//  Created by chris Lee on 18/11/2023.
//https://developers.google.com/youtube/v3/quickstart/ios?ver=swift




import Foundation
import GoogleAPIClientForREST


class YoutubeDataAPIService{
    
    var youTubeService: GTLRYouTubeService = {
        let service = GTLRYouTubeService()

        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them.
        service.shouldFetchNextPages = true

        // Have the service object set tickets to retry temporary error conditions
        // automatically.
        service.isRetryEnabled = true

        return service
    }()
    
    
    
//    func fetchMyChannelList() {
//        var  myPlaylists : GTLRYouTube_ChannelContentDetails_RelatedPlaylists
//        var channelListFetchError : Error
//
//        let service = youTubeService
//
//        let query = GTLRYouTubeQuery_ChannelsList.query(withPart: ["contentDetails"])
//        query.mine = true
//
//        // maxResults specifies the number of results per page. Since we earlier
//        // specified shouldFetchNextPages=true and this query fetches an object
//        // class derived from GTLRCollectionObject, all results should be fetched,
//        // though specifying a larger maxResults will reduce the number of fetches
//        // needed to retrieve all pages.
//        query.maxResults = 50
//
//        // We can specify the fields we want here to reduce the network
//        // bandwidth and memory needed for the fetched collection.
//        //
//        // For example, leave query.fields as nil during development.
//        // When ready to test and optimize your app, specify just the fields needed.
//        // For example, this sample app might use
//        //
//        // query.fields = "kind,etag,items(id,etag,kind,contentDetails)"
//
//        var channelListTicket : GTLRServiceTicket = youTubeService.executeQuery(query){
//            
//        }
//         
//        var channelListTicket : GTLRServiceTicket = youTubeService.executeQuery(query) { _, channelList, callbackError in
//            // Callback
//
//            // The contentDetails of the response has the playlists available for
//            // "my channel".
//            if let channel = channelList?.items?.first as? GTLRYouTube_Channel {
//                self.myPlaylists = channel.contentDetails?.relatedPlaylists
//            }
//            self.channelListFetchError = callbackError
//            self.channelListTicket = nil
//
//            if let playlists = self.myPlaylists {
//                self.fetchSelectedPlaylist()
//            }
//
//            self.fetchVideoCategories()
//            self.updateUI()
//        }
//    }

    
    
}

