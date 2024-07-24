//
//  APIRequestBuilder.swift
//  AdventureTube
//
//  Created by chris Lee on 22/7/2024.
//

import Foundation
@resultBuilder
struct APIComponentsBuilder {
    static func buildBlock(_ components: [String:String]...) -> URLComponents {
        var urlComponents = URLComponents()
        let queryItems = components.reduce([URLQueryItem]()) { result, dictionary in
            result + dictionary.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        //        var queryItems = [URLQueryItem]()
        //            for dictionary in components {
        //                for (key,value) in dictionary {
        //                    let queryItem  = URLQueryItem(name: key, value: value)
        //                    queryItems.append(queryItem)
        //                }
        //            }
        
        urlComponents.queryItems = queryItems
        return urlComponents
    }
}
