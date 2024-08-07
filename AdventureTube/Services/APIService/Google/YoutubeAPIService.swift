//
//  YoutubeService.swift
//  AdventureTube
//
//  Created by chris Lee on 24/12/21.
//
//  all the function here is base on the document on https://developers.google.com/youtube/v3
//
//  Google Developer Console for AdventureTube
//  https://console.cloud.google.com/apis/dashboard?pli=1&project=adventuretube-1639805164044

import Foundation
import Combine
import GoogleSignIn
import GoogleAPIClientForREST

class YoutubeAPIService  {
    
    //This is API_KYE for 3 APIs which is Maps SDK , Place API , Youtube Data API v3
    static let API_KEY = "AIzaSyAH7YanpO16LRNnSwLtrHejWDjbP3xlFq8"
    
    //https://developers.google.com/youtube/v3/guides/auth/server-side-web-apps
    static let youtubeContentReadScope = kGTLRAuthScopeYouTubeReadonly
    private let youtubeChannelBaseURLString = "https://youtube.googleapis.com/youtube/v3/channels"
    private let channelInfoPartFieldQuery = URLQueryItem(name: "part", value: "snippet,statistics,contentDetails")
    private let mineFieldQuery = URLQueryItem(name: "mine", value: "true")
    
    private let youtubeContentInfoBaseURLString = "https://youtube.googleapis.com/youtube/v3/playlistItems"
    private let youtubeContentInfoPartFieldQuery = URLQueryItem(name: "part", value: "snippet,contentDetails,id")
    //This 50 is max acceptable value and default is 5
    private let youtubeContentInfoMaxFieldQuery  = URLQueryItem(name: "maxResults", value: "50")
    private let youtubeContentInfoPageToken = URLQueryItem(name: "pageToken", value:"")
    /// https://developers.google.com/youtube/registering_an_application
    /// API Key is requied for a request that does not provide an OAuth 2.0 token
    /// the key identifies your project and provides API access,quota and reports
    private let keyFieldQuery  = URLQueryItem(name: "key", value: API_KEY)
    
    private var playListIdPublisher = PassthroughSubject<String,Error>()
    var cancellable : AnyCancellable?
    var cancellables = Set<AnyCancellable>()
    
    var nextPageToken : String?
    var prevPageToken : String?
    
    init(){
        print("init YoutubeAPIService")
    }
    
    
    /// https://youtube.googleapis.com/youtube/v3/channels?part=snippet%2Cstatistics%2CcontentDetails&mine=true
    /// part=snippet%2Cstatistics%2CcontentDetails
    /// &mine=true
    /// The property is used to build the URL for making a request to the Youtube Data API
    /// to fetch channel of "mine" information
    private lazy var channelInfoComponents: URLComponents? = {
        var comps = URLComponents(string: youtubeChannelBaseURLString)
        comps?.queryItems = [channelInfoPartFieldQuery,mineFieldQuery]
        return comps
    }()
    private lazy var channelInfoRequest: URLRequest? = {
        guard let components = channelInfoComponents,
              let url = components.url else {
            return nil
        }
        return URLRequest(url: url)
    }()
    
    /// https://youtube.googleapis.com/youtube/v3/playlistItems?
    /// part=snippet%2CcontentDetails%2Cid&
    /// maxResults=10&
    /// playlistId=UUMg4QJXtDH-VeoJvlEpfEYg
    private lazy var youtubeContentInfoComponents: URLComponents? = {
        var comps = URLComponents(string: youtubeContentInfoBaseURLString)
        comps?.queryItems = [youtubeContentInfoPartFieldQuery,youtubeContentInfoMaxFieldQuery]
        return comps
    }()
    //    private lazy var youtubeContentInfoRequest: URLRequest? = {
    //        guard let components = youtubeContentInfoComponents,
    //              let url = components.url else {
    //            return nil
    //        }
    //        return URLRequest(url: url)
    //    }()
    
    
    private func  youtubeContentInfoRequest(urlComponents : URLComponents) -> URLRequest {
        //        guard let components = urlComponents,
        //              let url = components.url else {
        //            return nil
        //        }
        return URLRequest(url: urlComponents.url!)
    }
    
    
    
    //    private lazy var session: URLSession? = {
    //        guard let accessToken = GIDSignIn
    //                .sharedInstance
    //                .currentUser?
    //                .authentication
    //                .accessToken else { return nil }
    //        let configuration = URLSessionConfiguration.default
    //        configuration.httpAdditionalHeaders = [
    //            "Authorization": "Bearer \(accessToken)"
    //        ]
    //        return URLSession(configuration: configuration)
    //    }()
    
    
    
    
    //it comes from GoogleSignIn V7  library Samples/Swift/DaysUntilBirthday/Shared/Services/BirthdayLoader
    // TODO: check the function test
    private func sessionWithFreshToken(completion: @escaping (Result<URLSession, Error>) -> Void) {
        GIDSignIn.sharedInstance.currentUser?.refreshTokensIfNeeded { user, error in
            guard let token = user?.accessToken.tokenString else {
                completion(.failure(.couldNotCreateURLSession(error)))
                return
            }
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = [
                "Authorization": "Bearer \(token)"
            ]
            let session = URLSession(configuration: configuration)
            completion(.success(session))
        }
        
        
        
        //set the user's authentication which is already updated birthday read permission
        //        let authentication = GIDSignIn.sharedInstance.currentUser?.authentication
        //        authentication?.do { auth, error in
        //            //get the token
        //            guard let token = auth?.accessToken else {
        //                /// so when completion get called
        //                /// MARK NO3
        //                completion(.failure(.couldNotCreateURLSession(error)))
        //                return
        //            }
        ////            print("==============================TOKEN==============================")
        ////            print(token)
        //            //set the token in header
        //            let configuration = URLSessionConfiguration.default
        //            configuration.httpAdditionalHeaders = [
        //                "Authorization": "Bearer \(token)"
        //            ]
        //
        //            // create session
        //            let session = URLSession(configuration: configuration)
        //
        //
        //            /// MARK NO3
        //            /// once all session has been set  , call the completion  by apssing a Enum Result<URLSession,Error> value
        //            /// that is storing sucess value
        //            completion(.success(session))
        //        }
    }
    
    // make function call much shorter
    func handleOutput(output: URLSession.DataTaskPublisher.Output) throws -> Data {
        guard
            let response = output.response as? HTTPURLResponse,
            response.statusCode >= 200 && response.statusCode < 300 else {
            throw URLError(.badServerResponse)
        }
        return output.data
    }
    
    
    // MARK: - youtubeContentResourcePublisher

    /// 1. About Method
    /// This method starts with a session check from GoogleSignIn, refreshing the token if needed.
    /// It creates a query to find the playlist ID and fetch the public YouTube content list from the channel.
    /// Once the playlist is successfully returned, it builds an `AnyPublisher<YoutubeContentResource, Error>`
    /// that the caller can listen to. This might require multiple calls to get the whole list and can be upgraded as the UI needs.
    /// The method returns that publisher if successful, or a completion with an error if it fails.
    ///
    /// 2. Query Pattern
    /// Step 1: Find the playlist ID from `contentDetails.relatedPlaylists.uploads` by querying `https://www.googleapis.com/youtube/v3/channels`.
    /// Step 2: Use that playlist ID to query `https://www.googleapis.com/youtube/v3/playlistItems`.
    func youtubeContentResourcePublisher(completion: @escaping (AnyPublisher<YoutubeContentResource, Error>) -> Void) {
        sessionWithFreshToken { [weak self]  result in
            guard let self = self else {return}
            
            
            //if session returned successfully
            switch result{
                case .success(let authSession):
                    guard let request = self.channelInfoRequest
                    else {
                        //if fail to create the query using a Fail Publisher which will terminate immediately
                        print("request build has been failed")
                        return completion(Fail(error: .couldNotCreateURLRequest).eraseToAnyPublisher())
                    }
                    print("request : \(request.description)")
                    /// the publisher of outside is actually youtube channelList query not ContentResouce
                    /// but inside will be the actual query to return the result .
                    /// so name of whole publisher will be ContentResource publisher
                    let youtubeContentResourcePublisher = authSession.dataTaskPublisher(for: request)
                    //  .print("youtubeChannelInfoPublisher")
                        .tryMap(self.handleOutput)
                        .decode(type: YoutubeChannelResource.self, decoder: JSONDecoder())
                        .tryMap{ youtubeChannelResource -> String in
                            var playListId : String = ""
                            //var videoCount : String = ""
                            youtubeChannelResource.items.forEach { item in
                                //print("playlistId =========>\(item.contentDetails.relatedPlaylists.uploads)")
                                playListId = item.contentDetails.relatedPlaylists.uploads
                                //print("youtubeChannelResource==========>")
                                //print(youtubeChannelResource)
                            }
                            return playListId
                        }
                        .mapError{ error -> Error in
                            guard let loaderError = error as? Error else{
                                return Error.couldNotFetchYoutube(underlying: error)
                            }
                            return loaderError
                        }
                        //if playListId  returned successfully
                        //create the query include maxCount and pageToken if that is exist
                        .map{ (playListId) -> AnyPublisher<YoutubeContentResource,Error>   in
                            
                            guard var  youtubeContentInfoComponents: URLComponents = self.youtubeContentInfoComponents else {
                                return Fail(error: Error.couldNotCreateURLRequest).eraseToAnyPublisher()
                            }
                            //need to add a pageToken here
                            youtubeContentInfoComponents.queryItems?.append( URLQueryItem(name: "playlistId", value: playListId))
                            if let nextPageToken = self.nextPageToken{
                                youtubeContentInfoComponents.queryItems?.append( URLQueryItem(name: "pageToken", value: nextPageToken))
                            }
                            let youtubeContentInfoRequest = self.youtubeContentInfoRequest(urlComponents: youtubeContentInfoComponents)
                            
                            ///create publisher   that will return YoutubeContentResouece  using a create query and return
                            return   authSession.dataTaskPublisher(for: youtubeContentInfoRequest)
                                .print("YoutubeContentPublisher")
                                .tryMap(self.handleOutput(output:))
                                .decode(type: YoutubeContentResource.self, decoder: JSONDecoder())
                                .mapError{ error -> Error in
                                    guard let loaderError = error as? Error else{
                                        return Error.couldNotFetchYoutube(underlying: error)
                                    }
                                    return loaderError
                                }
                                .eraseToAnyPublisher()
                        }
                        //switchToLatest() will flatten the sequence since the method is nested structure of
                        //AnyPublisher<AnyPublisher<YoutubeContentResource, Error>, Error>
                        //so without this called will need to handle AnyPublisher<AnyPublisher<YoutubeContentResource, Error>, Error>
                        //as received object instead of direct "YoutubeContentResource"
                        .switchToLatest()
                        .receive(on: DispatchQueue.main)
                        .eraseToAnyPublisher()
                    
                    completion(youtubeContentResourcePublisher)
                //if session returned fail
                case .failure(let error):
                    completion(Fail(error: error).eraseToAnyPublisher())
            }
        }
        
    }
    
    deinit{
        print("Youtube Service  is deinitizing now ~~~~")
    }
}


extension YoutubeAPIService {
    enum Error: Swift.Error {
        case couldNotCreateURLSession(Swift.Error?)
        case couldNotCreateURLRequest
        case userHasNoBirthday
        case couldNotFetchYoutube(underlying: Swift.Error)
    }
}
