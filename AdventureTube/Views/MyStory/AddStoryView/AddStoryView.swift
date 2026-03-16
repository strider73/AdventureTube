//
//  AddStoryView.swift
//  AdventureTube
//
//  Created by chris Lee on 28/3/22.
//

import SwiftUI
enum AddStoryViewActiveSheet: Identifiable {
    case uploadConfirmSheet
    case deleteConfirmSheet
    //    case deleteChapterWarningSheet
    //    case leaveWithoutCreateChapterWarningSheet
    case saveChangeWarningSheet

    var id: Int {
        hashValue
    }
}

struct CreateChapterViewData : Identifiable {
    var id: String{
        return youtubeViewVM.videoId
    }
    //    var adventureTubeData : AdventureTubeData?
    var youtubeViewVM : YoutubeViewVM
    var createChapterViewVM : CreateChapterViewVM
    var categorySelection : [Category] = []
    var selectedIndex : Int
}

struct AddStoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var nav: NavigationStateManager

    @EnvironmentObject private var loginManager : LoginManager
    @EnvironmentObject private var myStoryListVM : MyStoryListViewVM
    
    /// Architecture Note:
    /// - `AddStoryViewVM` is responsible for storing core data related to the story, such as activity, trip duration, video type, and confirmed location.
    /// - `AddStoryMapViewVM` handles Google Place and Map API interactions to obtain confirmed location data.
    /// Keeping these responsibilities separate helps maintain a clean architecture and avoids mixing concerns.
    
    @StateObject private var addStoryVM :AddStoryViewVM
    @StateObject private var youtubeViewVM: YoutubeViewVM
    
    @State var title : String
    
    @State private var youtubePopUpData : PlayChapterData?
    @State private var createChapterViewData : CreateChapterViewData?
    
    @State private var isShowNewStoryMapView =  false
    @State private var isEditable = false
    @State private var selectedIndex : Int = 0
    
    
    init(youtubeContentItem : YoutubeContentItem ,
         adventureTubeData : AdventureTubeData?){
        print("init AddStoryView!!!!!!")
        _addStoryVM = StateObject(wrappedValue:.init(youtubeContentItem: youtubeContentItem, adventureTubeData: adventureTubeData))
        _youtubeViewVM = StateObject(wrappedValue: .init(videoId: youtubeContentItem.contentDetails.videoId,
                                                         videoTitle:youtubeContentItem.snippet.title))
        _title = State(initialValue:youtubeContentItem.snippet.title)
        
    }
    
    //Error Message
    //    @State private var isShowErrorMessage = false
    //    @State private var errorMessage = ""
    
    var body: some View {
        ZStack(alignment: .top){
            ColorConstant.background.color.edgesIgnoringSafeArea(.all)
            
            
            VStack(alignment:.leading){
                // categoryPickerSection
                
                tripDurationSection
                    .padding(EdgeInsets(top: 20, leading: 5, bottom: 5, trailing: 5))
                
                videoTypeSection
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                
                HStack{
                    Image(systemName: "location.circle")
                        .resizable()
                        .frame(width:30 , height: 30)
                        .foregroundColor(Color.black)
                    Text("create video chapter with map&category")
                    Spacer()
                    Button {
                        
                        addStoryVM.validateForCreateChaptor(){ isValidateError in
                            if isValidateError{
                                //error message will pop
                            }else{
                                //store new story in coredata with duration and type
                                //addStoryVM.saveNewStory()
                                segueForCreateChapter()
                            }
                        }
                        
                    } label: {
                        Image(systemName: "plus.circle")
                            .resizable()
                            .frame(width:30 , height: 30)
                            .foregroundColor(Color.black)
                    }
                    .foregroundColor(.black)
                    .fullScreenCover(item: $createChapterViewData, onDismiss: saveAllChanges) { createChapterViewData in
                        //this will allow AddStoryView listening googleMap's state
                        // changing of confirmed place using AddStoryMapViewViewModel
                        
                        CreateChapterView(youtubeViewVM :createChapterViewData.youtubeViewVM,
                                          /// confirmedPlace , confimedMaker . processState property in createChapterView has been already set
                                          /// and subscribe to update AddStoryView
                                          createChapterViewVM: createChapterViewData.createChapterViewVM,
                                          selectedIndex: createChapterViewData.selectedIndex )
                        
                    }
                    
                    
                }
                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                .onTapGesture {
                    print("link tapped")
                    isShowNewStoryMapView.toggle()
                }
                HStack{
                    VStack{
                        List{
                            ForEach(addStoryVM.chapters.indices , id : \.self){ index in
                                let chapter : AdventureTubeChapter = addStoryVM.chapters[index]
                                HStack{
                                    HStack{
                                        Text(chapter.place.name ?? "No place Name")
                                            .font(.system(size: 15, weight: .bold, design: .default))
                                            .lineLimit(1)
                                        Spacer()
                                        HStack{
                                            if chapter.youtubeTime > 0 {
                                                Text(TimeToString.getDisplayTime(chapter.youtubeTime))
                                                    .foregroundColor(Color.black)
                                                    .font(.system(size: 15, weight: .bold, design: .default))
                                            }else{
                                                Button {
                                                    self.selectedIndex = index
                                                    segueForCreateChapter()
                                                } label: {
                                                    Image(systemName: "play.circle")
                                                        .resizable()
                                                        .frame(width:30 , height: 30)
                                                        .foregroundColor(Color.black)
                                                }
                                                .withPressableStyle(scaledAmount: 0.5)
                                            }
                                            
                                            
                                        }
                                        
                                    }
                                    .frame(maxWidth:.infinity)
                                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                                    .background(Color.gray)
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        if chapter.youtubeTime > 0  {
                                            self.selectedIndex = index
                                            //segueForPlayChapter()
                                            segueForCreateChapter()
                                            
                                        }
                                    }
                                    
                                    Button {
                                        //delete location
                                        addStoryVM.deleteChapterAt(index: index)
                                    } label: {
                                        Image(systemName: "x.circle")
                                            .resizable()
                                            .frame(width:30 , height: 30)
                                            .foregroundColor(Color.black)
                                    }
                                    .withPressableStyle(scaledAmount: 0.5)
                                    
                                }
                                .overlay(getSmallCategoryImage(categories: chapter.categories), alignment: .topLeading)
                                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing:  0))
                                .listRowSeparator(.hidden)
                            }
                            .onMove(perform: move)
                            .onLongPressGesture {
                                withAnimation {
                                    self.isEditable = true
                                }
                            }
                        }
                        .environment(\.editMode, isEditable ? .constant(.active) : .constant(.inactive))
                        .listStyle(.plain)
                        .fullScreenCover(item: $createChapterViewData, onDismiss: saveAllChanges) { createChapterViewData in
                            //this will allow AddStoryView listening googleMap's state
                            // changing of confirmed place using AddStoryMapViewViewModel
                            
                            CreateChapterView(youtubeViewVM :createChapterViewData.youtubeViewVM,
                                              /// confirmedPlace , confimedMaker . processState property in createChapterView has been already set
                                              /// and subscribe to update AddStoryView
                                              createChapterViewVM: createChapterViewData.createChapterViewVM,
                                              selectedIndex: createChapterViewData.selectedIndex )
                            
                        }
                        
                    }
                }//HStack
                
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle(title)
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                       // nav.selectionPath.removeLast()
                        presentationMode.wrappedValue.dismiss()

                    } label: {
                        Image(systemName: "chevron.backward.circle")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.black)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if addStoryVM.isStoryPublished {
                        Button {
                            addStoryVM.actionSheet = .deleteConfirmSheet
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(addStoryVM.isPublishing ? Color.gray : Color.red)
                        }
                        .disabled(addStoryVM.isPublishing)
                    } else {
                        Button {
                            addStoryVM.actionSheet = .uploadConfirmSheet
                        } label: {
                            Image(systemName: "icloud.and.arrow.up.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(addStoryVM.isPublishing ? Color.gray : Color.black)
                        }
                        .disabled(addStoryVM.isPublishing)
                    }
                }
            }
            .alert(addStoryVM.errorMessage, isPresented: $addStoryVM.isShowErrorMessage){
                Button("OK", role: .cancel) { }
            }
            .actionSheet(item: $addStoryVM.actionSheet){ actionSheet in
                switch actionSheet {
                    case .saveChangeWarningSheet :
                        return ActionSheet(title: Text("Save Change Warning"),
                                           message: Text("One of your Content fild has been change , it wont be stored if you didnt save this change "),
                                           buttons: [
                                            .cancel{
                                                presentationMode.wrappedValue.dismiss()
                                            },
                                            .default(Text("Save change"),
                                                     action:{
                                                         // save data
                                                         addStoryVM.saveNewStory()
                                                         presentationMode.wrappedValue.dismiss()
                                                     })
                                           ])
                    case .uploadConfirmSheet:
                        return ActionSheet(title: Text("This will publish your story"), message: Text("publish your story"), buttons: [
                            .default(Text("publish"),
                                     action: {
                                         addStoryVM.uploadStory()
                                     }
                                    ),
                            .cancel()
                        ])
                    case .deleteConfirmSheet:
                        return ActionSheet(title: Text("Delete Published Story"), message: Text("This will remove your story from the server. Your local data will be kept."), buttons: [
                            .destructive(Text("Delete"),
                                         action: {
                                             addStoryVM.deletePublishedStory()
                                         }
                                        ),
                            .cancel()
                        ])
                }
            }
            .padding(EdgeInsets(top: 20, leading: 15, bottom: 20, trailing: 15))

            // MARK: - Publishing Status Overlay
            if addStoryVM.isPublishing {
                publishingOverlay
            }
        }

    }
    
    
    
    // MARK: - Publishing Overlay

    private var publishingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {} // Block taps on background

            VStack(spacing: 20) {
                publishingStatusContent
            }
            .frame(width: 280)
            .padding(30)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }

    @ViewBuilder
    private var publishingStatusContent: some View {
        switch addStoryVM.publishingStatus {
        case .uploading:
            ProgressView()
                .scaleEffect(1.5)
            Text("Uploading story...")
                .font(.headline)
        case .streaming:
            ProgressView()
                .scaleEffect(1.5)
            Text("Publishing...")
                .font(.headline)
            Text("Receiving real-time updates")
                .font(.caption)
                .foregroundColor(.gray)
        case .pollingFallback:
            ProgressView()
                .scaleEffect(1.5)
            Text("Publishing...")
                .font(.headline)
            Text("Checking status...")
                .font(.caption)
                .foregroundColor(.gray)
        case .completed(let chaptersCount, let placesCount):
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.green)
            Text("Published!")
                .font(.headline)
            Text("\(chaptersCount) chapters, \(placesCount) places")
                .font(.subheadline)
                .foregroundColor(.gray)
            Button("OK") {
                addStoryVM.dismissPublishingOverlay()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        case .deleted:
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.green)
            Text("Deleted!")
                .font(.headline)
            Text("Your story has been removed from the server.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("OK") {
                addStoryVM.dismissPublishingOverlay()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        case .duplicate:
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.orange)
            Text("Already Exists")
                .font(.headline)
            Text("This story has already been published.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("OK") {
                addStoryVM.dismissPublishingOverlay()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        case .failed(let message):
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.red)
            Text("Publishing Failed")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("OK") {
                addStoryVM.dismissPublishingOverlay()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        case .idle:
            EmptyView()
        }
    }

    func saveAllChanges(){
        //        if let selectedIndex = selectedIndex , let updateYoutubeTime = youtubeViewVM.currentTime {
        //            addStoryVM.confirmedPlaces[selectedIndex].youtubeTime = updateYoutubeTime
        //        }
    }
    
    func getSmallCategoryImage(categories : [Category])  -> some View {
        HStack{
            ForEach(categories){ category in
                //Text(category.key).smallCategoryIcon(isSelected:true, withColor : Color.orange)
                Image(category.key)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .cornerRadius(3)
            }
        }
        .padding([.top,.leading],5)
        .offset(y:-10)
    }
    
    //This addStoryVM.createChapterViewVM has confimedPlaceData(ATGooglePlace) which is already
    //subscribed in AdStoryViewVM and also assigned all data from adventureTubeData(AdventureTubeData)
    //so any update for confirmed data will automatically applid to AddStoryView
    //and will be ready to store in coredata
    func segueForCreateChapter(){
        
        var categorySelection : [Category]
        if let adventureTubeData = addStoryVM.adventureTubeData {
            categorySelection = adventureTubeData.userContentCategory
        }else{
            categorySelection = addStoryVM.categorySelection
        }
        
        
        
        createChapterViewData = CreateChapterViewData(youtubeViewVM: youtubeViewVM,
                                                      createChapterViewVM: addStoryVM.createChapterViewVM,
                                                      categorySelection: categorySelection,
                                                      selectedIndex: self.selectedIndex)
        
        
    }
    
    
    func move(from source: IndexSet, to destination: Int) {
        addStoryVM.places.move(fromOffsets: source, toOffset: destination)
        withAnimation {
            isEditable = false
        }
    }
    
    //Category Picker Section
    //    private var categoryPickerSection : some View {
    //        VStack(alignment:.leading){
    //            HStack{
    //                Image(systemName: "globe.asia.australia")
    //                    .resizable()
    //                    .frame(width:30 , height: 30)
    //                    .foregroundColor(Color.black)
    //                Text("Activity")
    //            }
    //
    //            categoryPicker
    //        }
    //
    //    }
    //    private var categoryPicker : some  View {
    //        VStack(spacing: 13.0){
    //            ForEach(addStoryVM.getCategoryList(),id:\.self){
    //                contentCategoryarray in
    //                HStack(spacing:13) {
    //                    ForEach(contentCategoryarray,id:\.self){ contentCategory in
    //                        Button{
    //
    //                            if let index = addStoryVM.categorySelection.firstIndex(of: contentCategory){
    //                                addStoryVM.categorySelection.remove(at: index)
    //                            }else{
    //                                addStoryVM.categorySelection.append(contentCategory)
    //                            }
    //
    //                        }label: {
    //                            if addStoryVM.categorySelection.contains(contentCategory){
    //                                Text(contentCategory.key)
    //                                    .categoryIcon(isSelected: true)
    //                            }else{
    //                                Text(contentCategory.key)
    //                                    .categoryIcon(isSelected: false)
    //                            }
    //                        }
    //                        .categorybutton()
    //                    }
    //                }
    //            }
    //        }.padding(4)
    //    }
    
    
    
    private var tripDurationSection : some View {
        HStack{
            Image(systemName: "calendar.badge.clock")
                .resizable()
                .frame(width:35 , height: 30)
                .foregroundColor(Color.black)
            Text("Trip Duration")
            Spacer()
            Menu{
                Picker(selection: $addStoryVM.durationSelection, label: EmptyView()) {
                    ForEach(Duration.allCases){
                        Text("\($0.rawValue)")
                    }
                }
            } label: {
                tripDurationCustomLabel
            }
        }
    }
    
    private  var tripDurationCustomLabel : some View {
        HStack{
            Text(addStoryVM.durationSelection.rawValue)
            Image(systemName: "chevron.down")
        }
        .frame(width: 170 ,height: 40 )
        .foregroundColor(.black)
        .background( ZStack{
            Color.gray
            Color.white
                .padding(2)
                .cornerRadius(15)
        })
        .cornerRadius(10)
    }
    
    
    private  var videoTypeSection : some View {
        HStack{
            
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width:30 , height: 30)
                .foregroundColor(Color.black)
            Text("Video Type")
            Spacer()
            Menu{
                Picker(selection: $addStoryVM.videoTypeSelection, label: EmptyView()) {
                    ForEach(ContentType.allCases){
                        Text("\($0.rawValue)")
                    }
                }
            } label: {
                videoCustomLabel
            }
            
        }
    }
    
    
    private   var videoCustomLabel : some View {
        HStack{
            Text(addStoryVM.videoTypeSelection.rawValue)
            Image(systemName: "chevron.down")
        }
        .frame(width: 170 ,height: 40 )
        .foregroundColor(.black)
        .background( ZStack{
            Color.gray
            Color.white
                .padding(2)
                .cornerRadius(15)
        })
        .cornerRadius(10)
    }
    
    
    private var locationSection : some View {
        HStack{
            Image(systemName: "location.circle")
                .resizable()
                .frame(width:30 , height: 30)
                .foregroundColor(Color.black)
            Text("location")
            Spacer()
            Image(systemName: "chevron.forward")
                .frame(width: 150, height: 40 , alignment: .trailing)
                .onTapGesture {
                    isShowNewStoryMapView.toggle()
                }
            
        }
    }
    
    
    //This one is common
    private func getListTitle() -> String {
        guard let userName = loginManager.userData.givenName else{
            return "Adventure Story"
        }
        return userName + "'s Adventure Story"
    }
    
    
    
}

struct AddStoryView_Previews: PreviewProvider {
    @State static var path: [String] = []
    
    
    static var previews: some View {
        NavigationStack{
            AddStoryView(youtubeContentItem: dev.youtubeContentItems.first!,
                         adventureTubeData: dev.youtubeContentItems.first!.snippet.adventureTubeData)
            .environmentObject(dev.loginManager)
            .environmentObject(dev.myStoryVM)
        }
    }
}
