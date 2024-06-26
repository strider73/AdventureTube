//
//  NewStoryView.swift
//  AdventureTube
//
//  Created by chris Lee on 16/3/22.
//

import SwiftUI
struct StoryLoadingView : View {
    
    var youtubeContentItem : YoutubeContentItem?
    var adventureTubeData :  Published<AdventureTubeData?>.Publisher
    init(youtubeContentItem:YoutubeContentItem? ,adventureTubeData:Published<AdventureTubeData?>.Publisher){
        print("init StoryLoadingView!!!!!!")
        self.youtubeContentItem = youtubeContentItem
        self.adventureTubeData = adventureTubeData
        
    }

    
    var body : some View {
        ZStack{
            if let youtubeContentItem = youtubeContentItem{
                StoryView(youtubeContentItem: youtubeContentItem, adventureTubeData: adventureTubeData)
                    .navigationBarBackButtonHidden(true)

            }
        }

    }
    
    
}



struct StoryView: View {
    // need to be initialized with youtubeContentItem
    @EnvironmentObject private var myStoryListVM : MyStoryListViewVM
    
    @StateObject private var myStoryDetailViewVM  : MyStoryCommonDetailViewVM
    @StateObject var youtubeViewVM : YoutubeViewVM

    @State var title : String
    
    @State var storyEntity : StoryEntity?
    @State var buttons : [CustomNavBarButtonItem] = []
    @State private var isDescriptionEditorShow = false
    @State private var isCreateNewStory = false
    @State private var isUpdateStory = false
    
    init(youtubeContentItem : YoutubeContentItem , adventureTubeData:  Published<AdventureTubeData?>.Publisher){
        print("init StoryView!!!!!!")
        _myStoryDetailViewVM = StateObject(wrappedValue: MyStoryCommonDetailViewVM(youtubeContentItem:youtubeContentItem ,
                                                                                   adventureTubeData:adventureTubeData))
        _youtubeViewVM = StateObject(wrappedValue: YoutubeViewVM(videoId: youtubeContentItem.contentDetails.videoId))
        
        title = youtubeContentItem.snippet.title
 
    }
    
    
    var body : some View {
        ZStack(alignment: .top) {
            ColorConstant.background.color.edgesIgnoringSafeArea(.all)
            VStack(spacing:0)
            {
                YoutubeView(youtubeViewVM: self.youtubeViewVM)
                    .frame(height: 220 )
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1),
                                            radius: 46,
                                                  x: 0,
                                                  y: 15)
/* This might need as offline function
//                if let image = myStoryDetailViewVM.image {
//                    Image(uiImage:image)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                }else if myStoryDetailViewVM.isLoading{
//                    ProgressView()
//                }else {
//                    Image(systemName: "questionmark")
//                        .foregroundColor(Color.red)
//                }
*/
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                
//                if let adventureTubeData = myStoryDetailViewVM.adventureTubeData {
//                    HStack{
//                        ForEach(adventureTubeData.userContentCategory , id: \.self){ category in
//                            if  let categoryChar = ContentCategory(rawValue: category){
//                                Text(categoryChar.key)
//                                    .font(Font.custom("momentale-categories", size: 22))
//                            }
//                        }
//                    }
//                }
                
                
                ZStack{
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(Color.white)
                        .background(
                            Color.gray
                        )
                        .padding(1)
                    
                    VStack{
                        
                        if let adventureTubeData = myStoryDetailViewVM.adventureTubeData {
                            HStack{
                                
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width:30 , height: 30)
                                        .foregroundColor(Color.black)
                                    Text("\(adventureTubeData.userContentType.rawValue)")
                                        .font(.caption2)
                                }
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                Spacer()
                                
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .resizable()
                                        .frame(width:30 , height: 30)
                                        .foregroundColor(Color.black)
                                    Text("\(adventureTubeData.userTripDuration.rawValue)")
                                        .font(.caption2)
                                }
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                Spacer()

                                HStack {
                                    Image(systemName: "bookmark.circle")
                                        .resizable()
                                        .frame(width:30 , height: 30)
                                        .foregroundColor(Color.black)
                                    Text("\(adventureTubeData.chapters.count)")
                                        .font(.caption2)
                                }
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

                            }
                        }
                        
                        
                        HStack(alignment:.top){
                            Image(systemName: "pencil")
                            Text("Description")
                                .font(.caption)
                            Spacer()
                        }
                        .padding(5)
                        ScrollView{
                            Text(myStoryDetailViewVM.desciption)
                                .font(.footnote)
                                .onTapGesture {
                                    isDescriptionEditorShow.toggle()
                                }
                            
                        }
                        Spacer()
                        
                    }.padding(15)
                        .sheet(isPresented: $isDescriptionEditorShow,
                               onDismiss: {
                            // neet to store the update descripton on database
                        }) {
                            DescriptionEditorView(description: $myStoryDetailViewVM.desciption)
                        }
                }
                .background(Color.black)
                .cornerRadius(25)
                .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                .shadow(color: .black.opacity(0.7), radius: 1, x: 0, y: 2)
                
                
            }
            
        }
        .customNavBarItems(title: title, buttons: myStoryDetailViewVM.buttons)
        .onAppear {
        
            
        }
        .background(
            CustomNavLink(                //Do not use adventureTubeData here since it wont get anyupdate
                destination: AddStoryView(youtubeContentItem: myStoryDetailViewVM.selectedYoutubeContentItem ,
                                          //adventureTubeData from youtubeContentItemsPublisher , which will always get update
                                          adventureTubeData: myStoryDetailViewVM.adventureTubeData),
                isActive: $myStoryDetailViewVM.isShowAddStory,
                label: {EmptyView()}
            )
            
        )
    }
    
    
    func createDescription(){
        
    }
    
}

struct NewStoryView_Previews: PreviewProvider {
    static var previews: some View {
        CustomNavView{
            StoryView(youtubeContentItem: dev.youtubeContentItems.first! , adventureTubeData: dev.myStoryVM.$adventureTubeData)
                .environmentObject(dev.myStoryVM)
        }
    }
}
