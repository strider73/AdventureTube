// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let youtubeContentResource = try? newJSONDecoder().decode(YoutubeContentResource.self, from: jsonData)

import Foundation
import CoreLocation

// MARK: - YoutubeContentResource
struct YoutubeContentResource: Codable {
    let nextPageToken : String?
    let prevPageToken : String?
    let kind, etag: String
    let items: [YoutubeContentItem]
    let pageInfo: YoutubeContentPageInfo

}

// MARK: - Item
struct YoutubeContentItem: Codable ,Identifiable, Equatable {
    let kind, etag, id: String
    var snippet: YoutubeContenSnippet
    let contentDetails: YoutubeContentDetails
    
    //Why this is for Equatable ???
    static func == (lhs: YoutubeContentItem, rhs: YoutubeContentItem) -> Bool {
        // Implement your equality check here based on the properties you want to compare
        return lhs.id == rhs.id
    }
}

// MARK: - ContentDetails
struct YoutubeContentDetails: Codable {
    //This is id for viideo resource
    let videoId: String
    let videoPublishedAt: String

    enum CodingKeys: String, CodingKey {
        case videoId
        case videoPublishedAt
    }
}

// MARK: - Snippet
struct YoutubeContenSnippet: Codable {
    let description: String?
    let publishedAt: String
    let channelId, title :String
    let thumbnails: YoutubeContentThumbnails
    let channelTitle, playlistId: String
    let position: Int
    let resourceId: ResourceID
    let videoOwnerChannelTitle, videoOwnerChannelId: String
    //additionalData from Adventure tube
    var adventureTubeData : AdventureTubeData?

    enum CodingKeys: String, CodingKey {
        case publishedAt
        case channelId
        case title
        case description
        case thumbnails, channelTitle
        case playlistId
        case position
        case resourceId
        case videoOwnerChannelTitle
        case videoOwnerChannelId
        case adventureTubeData
    }
}


// MARK: - ResourceID
struct ResourceID: Codable {
    let kind, videoId: String

    enum CodingKeys: String, CodingKey {
        case kind
        case videoId
    }
}

// MARK: - Thumbnails
struct YoutubeContentThumbnails: Codable {
    let thumbnailsDefault: YoutubeContentDefault?
    let  medium, high, standard : YoutubeContentDefault?
    let maxres: YoutubeContentDefault?

    enum CodingKeys: String, CodingKey {
        case thumbnailsDefault
        case medium, high, standard, maxres
    }
}

// MARK: - Default
struct YoutubeContentDefault: Codable {
    let url: String
    let width, height: Int
}

// MARK: - PageInfo
struct YoutubeContentPageInfo: Codable {
    let totalResults, resultsPerPage: Int
}


/*
 https://developers.google.com/youtube/v3/docs/playlistItems/list
 
 'https://youtube.googleapis.com/youtube/v3/playlistItems?part=snippet%2CcontentDetails%2Cid&maxResults=2&playlistId=UUMg4QJXtDH-VeoJvlEpfEYg&key=[YOUR_API_KEY]' \
   --header 'Authorization: Bearer [YOUR_ACCESS_TOKEN]' \
   --header 'Accept: application/json' \
   --compressed
 
 
 {
   "kind": "youtube#playlistItemListResponse",
   "etag": "5zVhz-7V7GNnySPFkRdA735WnYE",
   "nextPageToken": "EAAaBlBUOkNBSQ",
   "items": [
     {
       "kind": "youtube#playlistItem",
       "etag": "XO0hMFOqk76mlgalPvFlICQP5nY",
       "id": "VVVNZzRRSlh0REgtVmVvSnZsRXBmRVlnLkNDSVMzLW9oc0pF",
       "snippet": {
         "publishedAt": "2022-01-21T02:17:47Z",
         "channelId": "UCMg4QJXtDH-VeoJvlEpfEYg",
         "title": "Sharps Camping Area   and Hiking at Sheoak Picnic area  4K",
         "description": "Sharps Camping Area   and Hiking at Sheoak Picnic area  4K",
         "thumbnails": {
           "default": {
             "url": "https://i.ytimg.com/vi/CCIS3-ohsJE/default.jpg",
             "width": 120,
             "height": 90
           },
           "medium": {
             "url": "https://i.ytimg.com/vi/CCIS3-ohsJE/mqdefault.jpg",
             "width": 320,
             "height": 180
           },
           "high": {
             "url": "https://i.ytimg.com/vi/CCIS3-ohsJE/hqdefault.jpg",
             "width": 480,
             "height": 360
           },
           "standard": {
             "url": "https://i.ytimg.com/vi/CCIS3-ohsJE/sddefault.jpg",
             "width": 640,
             "height": 480
           },
           "maxres": {
             "url": "https://i.ytimg.com/vi/CCIS3-ohsJE/maxresdefault.jpg",
             "width": 1280,
             "height": 720
           }
         },
         "channelTitle": "Adventure victoria",
         "playlistId": "UUMg4QJXtDH-VeoJvlEpfEYg",
         "position": 0,
         "resourceId": {
           "kind": "youtube#video",
           "videoId": "CCIS3-ohsJE"
         },
         "videoOwnerChannelTitle": "Adventure victoria",
         "videoOwnerChannelId": "UCMg4QJXtDH-VeoJvlEpfEYg"
       },
       "contentDetails": {
         "videoId": "CCIS3-ohsJE",
         "videoPublishedAt": "2022-01-31T21:00:03Z"
       }
     },
     {
       "kind": "youtube#playlistItem",
       "etag": "fsBGPGXMn8Q7BhsHzetQQpqBEwA",
       "id": "VVVNZzRRSlh0REgtVmVvSnZsRXBmRVlnLlNNbmdCOUFlXzRN",
       "snippet": {
         "publishedAt": "2021-10-07T01:22:55Z",
         "channelId": "UCMg4QJXtDH-VeoJvlEpfEYg",
         "title": "Yalla Valley Park   4K",
         "description": "Video has been taken at 11th April 2021 which we have no idea that  we won't be able to go camping again over  8 month .\n\nThis is actually  celebrate party with my 4 other korean family since we thought that we are \nalready out of the tunnel of COVID and haven't seem them after this camping !!!\n\nHope that  it wont happen again  ...NO GOING BACK .\n\nNow ,I have lot of plan to going a camping in November and December . \nSo we see you around in forest again very soon !!!!",
         "thumbnails": {
           "default": {
             "url": "https://i.ytimg.com/vi/SMngB9Ae_4M/default.jpg",
             "width": 120,
             "height": 90
           },
           "medium": {
             "url": "https://i.ytimg.com/vi/SMngB9Ae_4M/mqdefault.jpg",
             "width": 320,
             "height": 180
           },
           "high": {
             "url": "https://i.ytimg.com/vi/SMngB9Ae_4M/hqdefault.jpg",
             "width": 480,
             "height": 360
           },
           "standard": {
             "url": "https://i.ytimg.com/vi/SMngB9Ae_4M/sddefault.jpg",
             "width": 640,
             "height": 480
           },
           "maxres": {
             "url": "https://i.ytimg.com/vi/SMngB9Ae_4M/maxresdefault.jpg",
             "width": 1280,
             "height": 720
           }
         },
         "channelTitle": "Adventure victoria",
         "playlistId": "UUMg4QJXtDH-VeoJvlEpfEYg",
         "position": 1,
         "resourceId": {
           "kind": "youtube#video",
           "videoId": "SMngB9Ae_4M"
         },
         "videoOwnerChannelTitle": "Adventure victoria",
         "videoOwnerChannelId": "UCMg4QJXtDH-VeoJvlEpfEYg"
       },
       "contentDetails": {
         "videoId": "SMngB9Ae_4M",
         "videoPublishedAt": "2021-10-23T04:26:51Z"
       }
     }
   ],
   "pageInfo": {
     "totalResults": 38,
     "resultsPerPage": 2
   }
 }
 
 */
