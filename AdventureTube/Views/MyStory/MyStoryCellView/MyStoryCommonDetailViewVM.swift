//
//  MyStoryCellViewModel.swift
//  AdventureTube
//
//  Created by chris Lee on 11/3/22.
//

import Foundation
import SwiftUI
import Combine
import CoreData

class MyStoryCommonDetailViewVM : ObservableObject{
    
    
    //parameter for init method
    let selectedYoutubeContentItem : YoutubeContentItem
    //    let youtubeContentItemsPublisher : Published<[YoutubeContentItem]>.Publisher
    let adventureTubeDataPublisher : Published<AdventureTubeData?>.Publisher
    
    /// This adventureTubeData include all user's data
    /// 1. initially from downloadYotubeContentsAndMappedWithCoreData
    /// 2. upadte when any new data or data has been update from listenCoreDataSaveAndUpdate()
    @Published var adventureTubeData: AdventureTubeData?
    @Published var desciption : String = ""
    @Published var image:UIImage? = nil
    @Published var isLoading:Bool = false
    @Published var buttons : [CustomNavBarButtonItem] = []
    @Published  var isShowAddStory  = false

    var imageSubscription:AnyCancellable?
    private let fileManager = LocalImageFileManager.instance
    let manager = CoreDataManager.instance
    
    private let imageName : String
    private var cancellables = Set<AnyCancellable>()
    private var defaultDescription = "Tell us about your story.. We will create yours "
    
    
    /// there is two main parameter in this class
    /// 1) youtubeContentItem  : Youtube  content data for each detail ( cellView , detailView , updateView)
    /// 2) youtubeContentItems : Youtube content List Data tio listening any change that need to be inspected
    
    init(youtubeContentItem : YoutubeContentItem , adventureTubeData : Published<AdventureTubeData?>.Publisher){
        print("init MyStoryCommonDetailViewVM~~~~~~~~~~~~~~~~~")
        
        self.selectedYoutubeContentItem = youtubeContentItem
        self.adventureTubeData = youtubeContentItem.snippet.adventureTubeData
        //inital assign
        self.adventureTubeDataPublisher = adventureTubeData
        imageName = youtubeContentItem.contentDetails.videoId+"thumbnailImage"
        buttons = [.back , .addNewStory(myStoryCommonDetailViewVM: self)]
        getThumbnailImage()
        getAdventureTubeDataFromPublisher()
        setChapterDescription()
    }
    

    
    
    private func getThumbnailImage(){
        isLoading = true
        if let savedImnage   = fileManager.getImage(imageName: imageName) {
            image = savedImnage
            print("Retrieved image from File Manager!")
        }else{
            downloadImage()
            print("Downloading image now")
        }
    }
    
    private func downloadImage(){
        //logic for try max first and using a medium for back up
        var imageData :YoutubeContentDefault
        if  selectedYoutubeContentItem.snippet.thumbnails.maxres != nil {
            imageData = selectedYoutubeContentItem.snippet.thumbnails.maxres!
        }else {
            guard let mediumData = selectedYoutubeContentItem.snippet.thumbnails.medium
            else{
                return
            }
            imageData = mediumData
        }
        let imageUrl = URL(string : imageData.url)!
        
        
        imageSubscription =  DownloadPublisher.downloadData(url:imageUrl)
            .tryMap({ data -> UIImage? in
                return UIImage(data: data)
            })
            .sink(receiveCompletion: DownloadPublisher.handleCompletion,
                  receiveValue: {[weak self] returnImage in
                guard let self = self,
                      let returnImage = returnImage
                else {return}
                self.image = returnImage
                self.imageSubscription?.cancel()
                self.isLoading = false
                DispatchQueue.global(qos: .userInitiated).async() {
                    self.fileManager.saveImage(image: returnImage, imageName: self.imageName)
                }
            })
    }
    
    
    //    ///This will bring the composed story from CoreData
    //    func findStoryEntityForYoutubeId(){
    //
    //        if let story = myStoryListVM.stories.first(where: { story  in
    //            story.youtubeId == youtubeContentItem.id
    //        }) {
    //            self.story = story
    //        }
    //    }
    
    
    //This will update adventureTubeData if there any data has been inserted or updated
    func getAdventureTubeDataFromPublisher(){
        //listen any change from adventureTubeData and check the viode id
        adventureTubeDataPublisher
            .sink {[weak self] adventureTubeData in
                if let adventureTubeData = adventureTubeData{
                    //and set the local property of adventureTubeData if videoId is matched
                    if(self?.selectedYoutubeContentItem.contentDetails.videoId == adventureTubeData.youtubeContentID){
                        self?.adventureTubeData = adventureTubeData
                        //update description
                        self?.setChapterDescription()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func getCategoriesToString() -> [String]{
        if let adventureTubeData = adventureTubeData {
            return adventureTubeData.userContentCategory.map {$0.rawValue}
        }else{
            return []
        }
    }
    
    func setChapterDescription() {
        if let adventureTubeData = adventureTubeData {
            var chapterDescription = ""
            var index = 1
            let orderedChapter =    adventureTubeData.chapters.sorted{$0.youtubeTime < $1.youtubeTime}
            
            orderedChapter.forEach { chapter in
                chapterDescription = chapterDescription + " " +
                                     TimeToString.getYoutubeTime(chapter.youtubeTime) + " : " +
                                     String(" chapter") + String(index) +
                                     String(" @") + String(chapter.place.name) +
                                     String(" ") + String(getCategoryStringAtChapter(index : index-1)) +
                                     ". \r\n"
                
                
                index = index + 1
            }
   
//            orderedChapters.enumerated().map{(index ,  chapter) in
//                chapterDescription = index + " " + chapter.youtubeTime + " : " + chapter.categories.first?.rawValue
//                + "  at place " + chapter.place.name
//            }
//
            desciption = chapterDescription
            
        }
    }
    
    func getCategoryStringAtChapter(index : Int) -> String {
        var categroyString = ""

        if let adventureTubeData = adventureTubeData {
            let categories = adventureTubeData.chapters[index].categories
            categories.forEach { category in
                categroyString = categroyString + " #"+category.rawValue
            }
        
        }
        
        return categroyString
    }
    
}
