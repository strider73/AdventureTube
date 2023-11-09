//
//  ReadJsonData.swift
//  AdventureTube
//
//  Created by chris Lee on 15/3/22.
//

import Foundation

class ReadJsonData  {
    var youtubeContentResource :YoutubeContentResource!
    
    init(){
        loadData()
    }
    
    func loadData(){
        guard let url = Bundle.main.url(forResource: "YoutubeContentResource", withExtension: "json")
        else{
            print("Json File not found")
            return
        }
        
        let data = try? Data(contentsOf: url)
        print("========================= Youtube Content Json Data =============================")
        let jsonString = String(data: data!, encoding: .utf8)  ?? "No Youtube Content Data "
        print(jsonString)
        do{
            let youtubeContentResource = try? JSONDecoder().decode(YoutubeContentResource.self, from: data!)
            self.youtubeContentResource = youtubeContentResource!
        }catch{
            print(error)
        }
    }
}
