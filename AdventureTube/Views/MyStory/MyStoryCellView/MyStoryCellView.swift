//
//  MyStoryCellView.swift
//  AdventureTube
//
//  Created by chris Lee on 11/3/22.
//

import SwiftUI

struct MyStoryCellView: View {
    @StateObject var myStoryCommonDetailVM : MyStoryCommonDetailViewVM
    // Model does require YoutubeContentItem to be initicialized
    
    @State var youtubeContentItem : YoutubeContentItem
    init( youtubeContentItem: YoutubeContentItem ,
          adventureTubeData :Published<AdventureTubeData?>.Publisher ){
        _myStoryCommonDetailVM = StateObject(wrappedValue: MyStoryCommonDetailViewVM(youtubeContentItem: youtubeContentItem, adventureTubeData: adventureTubeData))
        self.youtubeContentItem = youtubeContentItem
    }
    
    var body: some View {
        VStack{
            if let image = myStoryCommonDetailVM.image {
                Image(uiImage:image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(3)
                //                    .frame(width: 343, height: 194)
                    .padding(EdgeInsets(top: 2, leading: 3, bottom: 0, trailing: 3))
                    .categoryWatermark(with: myStoryCommonDetailVM.getCategoriesToString())
                    .publishWatermark(isPublished: myStoryCommonDetailVM.adventureTubeData?.isPublished ?? false)
                
            }else if myStoryCommonDetailVM.isLoading{
                ProgressView()
            }else {
                Image(systemName: "questionmark")
                    .foregroundColor(Color.red)
            }
            VStack(alignment: .leading ,spacing: 5){
                Text(youtubeContentItem.snippet.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(top: 0, leading: 3, bottom: 0, trailing: 3))
                //1) check from initial loading
                //2) check from new insert data or update
                
                if let adventureTubeData = myStoryCommonDetailVM.adventureTubeData {
                    if adventureTubeData.chapters.count > 0 {
                    VStack{
                        HStack{
                            HStack{
                                Image(systemName: "calendar.badge.clock")
                                    .resizable()
                                    .frame(width:30 , height: 30)
                                    .foregroundColor(Color.black)
                                Text("\(adventureTubeData.userTripDuration.rawValue)")
                                    .font(.headline)
                            }
                            .padding(EdgeInsets(top: 0, leading: 3 , bottom: 0, trailing: 10))
                            
                            Spacer()
                            HStack{
                                Image(systemName: "bookmark.circle")
                                    .resizable()
                                    .frame(width:30 , height: 30)
                                    .foregroundColor(Color.black)
                                Text("\(adventureTubeData.chapters.count)")
                                    .font(.headline)
                            }
                            .padding(EdgeInsets(top: 0, leading: 3, bottom: 0, trailing: 10))
                        }
                        
                        HStack{
                            ScrollView(.horizontal){
                                HStack{
                                    ForEach(adventureTubeData.userContentCategory, id:\.self){ category in
                                        Image(category.rawValue)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 30, height: 30)
                                            .cornerRadius(5)
                                    }
                                }
                            }
                            .padding(EdgeInsets(top: 0, leading: 3, bottom: 0, trailing: 10))
                            Spacer()
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .resizable()
                                    .frame(width:30 , height: 30)
                                    .foregroundColor(Color.black)
                                Text("\(adventureTubeData.places.count)")
                                    .font(.headline)
                            }
                            .padding(EdgeInsets(top: 0, leading: 3, bottom: 0, trailing: 10))
                        }
                    }
                }
                }
            }
            .padding(6)
        }
        .onAppear {
            //check the story that has been insert
            //             myStoryListVM.story
        }
    }
}

struct MyStoryCellView_Previews: PreviewProvider {
    
    static var previews: some View {
        MyStoryCellView(youtubeContentItem:dev.youtubeContentItems.first! , adventureTubeData:  dev.myStoryVM.$adventureTubeData)
            .previewLayout(.fixed(width: 359, height: 312))
    }
}
