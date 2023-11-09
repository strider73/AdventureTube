// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let youtubeChannelResource = try? newJSONDecoder().decode(YoutubeChannelResource.self, from: jsonData)

import Foundation

// MARK: - YoutubeChannelResource
struct YoutubeChannelResource: Codable {
    let kind, etag: String
    let pageInfo: PageInfo
    let items: [Item]
}

// MARK: - Item
struct Item: Codable {
    let kind, etag, id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
    let statistics: Statistics
}

// MARK: - ContentDetails
struct ContentDetails: Codable {
    let relatedPlaylists: RelatedPlaylists
}

// MARK: - RelatedPlaylists
struct RelatedPlaylists: Codable {
    let likes, uploads: String
}

// MARK: - Snippet
struct Snippet: Codable {
    //This two data could  be nil anytime !!!!
    let customURL , country :String?
    let title, snippetDescription : String
    let publishedAt: String
    let thumbnails: Thumbnails
    let localized: Localized

    enum CodingKeys: String, CodingKey {
        case title
        case snippetDescription = "description"
        case customURL = "customUrl"
        case publishedAt, thumbnails, localized, country
    }
}

// MARK: - Localized
struct Localized: Codable {
    let title, localizedDescription: String

    enum CodingKeys: String, CodingKey {
        case title
        case localizedDescription = "description"
    }
}

// MARK: - Thumbnails
struct Thumbnails: Codable {
    let thumbnailsDefault, medium, high: Default

    enum CodingKeys: String, CodingKey {
        case thumbnailsDefault = "default"
        case medium, high
    }
}

// MARK: - Default
struct Default: Codable {
    let url: String
    let width, height: Int
}

// MARK: - Statistics
struct Statistics: Codable {
    let viewCount, subscriberCount: String
    let hiddenSubscriberCount: Bool
    let videoCount: String
}

// MARK: - PageInfo
struct PageInfo: Codable {
    let totalResults, resultsPerPage: Int
}

/*
 https://developers.google.com/youtube/v3/docs/channels/list
 
 
 'https://youtube.googleapis.com/youtube/v3/channels?part=snippet%2Cstatistics%2CcontentDetails&mine=true&key=[YOUR_API_KEY]' \
 --header 'Authorization: Bearer [YOUR_ACCESS_TOKEN]' \
 --header 'Accept: application/json' \
 --compressed

 
 {
   "kind": "youtube#channelListResponse",
   "etag": "p6qJaknKOz44yzp1Vu_ukFiXAsU",
   "pageInfo": {
     "totalResults": 1,
     "resultsPerPage": 5
   },
   "items": [
     {
       "kind": "youtube#channel",
       "etag": "FgZpRBlTDf8zdBiIpqJGov8nK84",
       "id": "UCMg4QJXtDH-VeoJvlEpfEYg",
       "snippet": {
         "title": "Adventure victoria",
         "description": "Hi, Guys. This is Adventure Victoria.\nMy Family has been camped around Victoria over 7 Years and had a lot of experience like a team.\nSo Channel is YES, Its about Family camping.\n\nI want to inspire other families (most likely who have a family member between 2 ~18)who never been camped or never camped in bushes to be entirely self-sufficient.\n\nFormat of the video  is most likely a combination of \n* Destination info\n* Campsite inspection \n* Activity you can try there \n* Site Set up \n* Food cooking \n* Some Camping Gear review \n* Total Cost (if we spend much more than average)\n\nThese will give your Family some of the information before you get there \nin various condition depend on the type of camping you want\nSince the preparation of camping will be quite a different base on the situation, which is.\n\n* How many days?\n* How many people?\n* what season?\n* what kind of activity we can try? \n\nHope I can see many others in the campsite, especially more Asian!\nAnd Please say hello to us when you",
         "customUrl": "adventurevictoria",
         "publishedAt": "2014-10-09T22:46:10Z",
         "thumbnails": {
           "default": {
             "url": "https://yt3.ggpht.com/ytc/AKedOLRVB2Hssgt-CBNXdKRfiQA1CYLLwDqUOvwwqQtp7Q=s88-c-k-c0x00ffffff-no-rj",
             "width": 88,
             "height": 88
           },
           "medium": {
             "url": "https://yt3.ggpht.com/ytc/AKedOLRVB2Hssgt-CBNXdKRfiQA1CYLLwDqUOvwwqQtp7Q=s240-c-k-c0x00ffffff-no-rj",
             "width": 240,
             "height": 240
           },
           "high": {
             "url": "https://yt3.ggpht.com/ytc/AKedOLRVB2Hssgt-CBNXdKRfiQA1CYLLwDqUOvwwqQtp7Q=s800-c-k-c0x00ffffff-no-rj",
             "width": 800,
             "height": 800
           }
         },
         "localized": {
           "title": "Adventure victoria",
           "description": "Hi, Guys. This is Adventure Victoria.\nMy Family has been camped around Victoria over 7 Years and had a lot of experience like a team.\nSo Channel is YES, Its about Family camping.\n\nI want to inspire other families (most likely who have a family member between 2 ~18)who never been camped or never camped in bushes to be entirely self-sufficient.\n\nFormat of the video  is most likely a combination of \n* Destination info\n* Campsite inspection \n* Activity you can try there \n* Site Set up \n* Food cooking \n* Some Camping Gear review \n* Total Cost (if we spend much more than average)\n\nThese will give your Family some of the information before you get there \nin various condition depend on the type of camping you want\nSince the preparation of camping will be quite a different base on the situation, which is.\n\n* How many days?\n* How many people?\n* what season?\n* what kind of activity we can try? \n\nHope I can see many others in the campsite, especially more Asian!\nAnd Please say hello to us when you"
         },
         "country": "AU"
       },
       "contentDetails": {
         "relatedPlaylists": {
           "likes": "LL",
           "uploads": "UUMg4QJXtDH-VeoJvlEpfEYg"
         }
       },
       "statistics": {
         "viewCount": "65168",
         "subscriberCount": "458",
         "hiddenSubscriberCount": false,
         "videoCount": "38"
       }
     }
   ]
 }

 */
