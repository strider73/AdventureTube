//
//  NewStoryView.swift
//  AdventureTube
//
//  Created by chris Lee on 16/3/22.
//

import SwiftUI

struct StoryView: View {
    // need to be initialized with youtubeContentItem
    @EnvironmentObject private var myStoryListVM : MyStoryListViewVM
    @EnvironmentObject var nav: NavigationStateManager

    @StateObject private var myStoryDetailViewVM  : MyStoryCommonDetailViewVM
    @StateObject var youtubeViewVM : YoutubeViewVM
    
    @State var title : String
    
    @State var storyEntity : StoryEntity?
    //@State var buttons : [CustomNavBarButtonInfo] = []
    @State private var isDescriptionEditorShow = false
    @State private var isCreateNewStory = false
    @State private var isUpdateStory = false
    
    init(youtubeContentItem : YoutubeContentItem , adventureTubeData:  Published<AdventureTubeData?>.Publisher){
        print("init StoryView!!!!!! of title \(youtubeContentItem.snippet.title)")
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
                
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // Action for back button
                    // You might need to dismiss the current view or navigate back
                    nav.selectionPath.removeLast()
                } label: {
                    Image(systemName: "chevron.backward.circle")
                        .foregroundColor(Color.black)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AddStoryView(youtubeContentItem: myStoryDetailViewVM.selectedYoutubeContentItem, adventureTubeData: myStoryDetailViewVM.adventureTubeData)) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(Color.black)
                }
                .navigationBarBackButtonHidden(true)
            }
        }
        
    }
    
    
    
    func createDescription(){
        
    }
    
}

struct NewStoryView_Previews: PreviewProvider {
    @State static var path: [String] = []
    
    static var previews: some View {
            StoryView(youtubeContentItem: dev.youtubeContentItems.first! , adventureTubeData: dev.myStoryVM.$adventureTubeData)
                .environmentObject(dev.myStoryVM)
        
    }
}
