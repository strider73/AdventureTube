
//
//  YoutubePopView.swift
//  AdventureTube
//
//  Created by chris Lee on 18/5/22.
//

import SwiftUI
import UIKit
import GooglePlaces
import GoogleMaps

enum CreateChapterViewActiveSheet: Identifiable {
    case isShow_DeleteChapter_ActionSheet,
         isShow_ConfirmadAddChapter_ActionSheet,
         isShow_FailAddchapter_ActionSheet
    
    var id: Int {
        hashValue
    }
}

struct ConfirmChapterModalData : Identifiable {
    var id = UUID()
    var createChapterViewVM : CreateChapterViewVM
}

struct CreateChapterView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    
    @ObservedObject var youtubeViewVM : YoutubeViewVM
    @ObservedObject var createChapterViewVM  : CreateChapterViewVM
    @State private var dynamicHeight: CGFloat = .zero
    
    
    //when is not ui test
    //    @FocusState private var searchTextInfocuse : Bool
    //for ui test
    // @State private var searchTextInfocuse : Bool = false
    @FocusState private var searchTextInfocuse : Bool
    
    
    @State var searchMapSheetData  : GoogleMapSheetViewData?
    @State var confirmChapterModalData : ConfirmChapterModalData?
    
//    @State private var selectedPlace : ATGooglePlace?
//    @State var selectedIndex : Int

    @State private var isCreateChapterModal = false
    
    
    @State var activeSheet : CreateChapterViewActiveSheet?
    @State private var deleteChapterIndex : Int = -1
    
    
    
    init(youtubeViewVM :  YoutubeViewVM ,
         createChapterViewVM : CreateChapterViewVM ,
         selectedIndex :Int){ // This category is about story not the location
        print("init CreateChapterView!!!!!!")
        
        self.youtubeViewVM = youtubeViewVM
        self.createChapterViewVM = createChapterViewVM
    }
    
    var body: some View {
        // This with .ignoresSafeArea(.keyboard, edges: .bottom)  prevent move up back ground screen
        // when keyboard appear
        GeometryReader { _ in
            
            ZStack {
                //ColorConstant.background.color.edgesIgnoringSafeArea(.all)
                VStack {
                    //Title Bar area ------>
                    HStack {
                        Button {
                            // need to alarm for saving a darta
                            presentationMode.wrappedValue.dismiss()
                        }label: {
                            Image(systemName: "archivebox")
                                .resizable()
                                .frame(width:30 , height: 30)
                                .foregroundColor(Color.black)
                        }
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                        Spacer()
                        Text(youtubeViewVM.videoTitle)
                            .foregroundColor(Color.black)
                            .font(.headline)
                        Spacer()
                        Button {
                                youtubeViewVM.pause()
                                segueForSearchMapSheet()
                            
                        } label: {
                            Image(systemName: "magnifyingglass.circle")
                                .resizable()
                                .frame(width:30 , height: 30)
                                .foregroundColor(Color.black)
                                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                        }
                    }
                    //Title Bar area ------<
                    videoAndCategorySection
                    googleMapSection
                }
                ConfirmChapterModalView(isShowing: $isCreateChapterModal,item:$confirmChapterModalData, size : .small ){ confirmChapterModalData in
                    if let confirmChapterModalData = confirmChapterModalData {
                    ConfirmChapterView(createChapterViewVM: confirmChapterModalData.createChapterViewVM,isShowing: $isCreateChapterModal)
                    }
                }
//                .customSheet(isShowing: $isCreateChapterModal, item: $confirmChapterModalData, size: .small){
//                        if let confirmChapterModalData = confirmChapterModalData {
//                        ConfirmChapterView(createChapterViewVM: confirmChapterModalData.createChapterViewVM)
//                        }
//                }
                .sheet(item: $searchMapSheetData) { searchMapSheetData in
                    GoogleSearchMapView(createChapterViewVM: searchMapSheetData.createChapterViewVM){
                        /*
                         This entire section is using a @ViewBuilder
                         it allow the same mapUI can be used in both
                               * GoogleSearchMapView
                               * CreateChapterView which is currentView itself
                         
                         and the [newMarker] which is value from the GoogleMapViewForCreateStoryControllerBridge
                         when it tapped by one of GMSMapViewDelegate method !!!!!
                         incredable !!!!
                            
                         */
                        
                        GoogleMapViewForCreateStoryControllerBridge(confirmedMarker: $createChapterViewVM.markers,
                                                      selectedMarker: $createChapterViewVM.selectedMarker,
                                                      isMarkerWillRedrawing:$createChapterViewVM.isMarkerWillRedrawing,
                                                      isGoogleMapSheetMode: $createChapterViewVM.isGoogleMapSheetMode,
                                                      //This will set the selecetedPlace from the tap on the Google Map
                                                      getPlaceFromTapOnMap:
                                                           {newMarker, placeId in//Step1 get the info from the DidTap on the map
                                                                        createChapterViewVM.setSelectedPlaceByTapAt(marker: newMarker, //Step2 set the selectedPlace
                                                                        placeId: placeId){createChapterViewVM.placeForChapter = $0}}
                        )
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear(){
                //            if createChapterViewVM.confirmedPlaces.count > 0 {
                //                youtubeViewVM.startTime =  createChapterViewVM.confirmedPlaces[selectedIndex].youtubeTime
                //            }
            }
            .actionSheet(item:$activeSheet) { item in
                switch item {
                case .isShow_DeleteChapter_ActionSheet :
                    return  ActionSheet(
                        title: Text("Delete confirmed location"),
                        message: Text("current selected location on your confimed list will be removed "),
                        buttons: [
                            .cancel {  },
                            .default(Text("Delete"),
                                     action: {
                                         print("delete index is \(deleteChapterIndex)")
                                         createChapterViewVM.deleteChapter(index: deleteChapterIndex)
                                     })
                        ]
                    )
                    
                case .isShow_ConfirmadAddChapter_ActionSheet :
                    return     ActionSheet(
                        title: Text("New Chapter"),
                        message: Text("\(createChapterViewVM.chapters[createChapterViewVM.selectedChapterIndex].place.name) will be chapter No\(createChapterViewVM.selectedChapterIndex+1) at time \(youtubeViewVM.getDisplayTime())"),
                        //                    message: Text("\(createChapterViewVM.confirmedPlaces[currentMapPointIndex].name) will be chapter No\(currentMapPointIndex+1) "),
                        
                        buttons: [
                            .cancel {  },
                            .default(Text("Add"),
                                     action: {
                                         createChapterViewVM.chapters[createChapterViewVM.selectedChapterIndex].youtubeTime = youtubeViewVM.currentTime ?? 0
                                         //createChapterViewVM.confirmedPlaces[selectedIndex].contentCategories = placeContentCategory
                                     })
                        ]
                    )
                    
                case .isShow_FailAddchapter_ActionSheet :
                    return     ActionSheet(
                        title: Text("Check the Addintioal Info"),
                        message: Text("New chapter require at lease one activity , location "),
                        buttons: [
                            .cancel { }
                        ]
                    )
                    
                }
            }
        }// geometry
        .ignoresSafeArea(.keyboard,edges: .all)// this will prevent screen move up whjen the keyboard appear in a backgroubnd
    }
    
    var googleMapSection : some View {
        
        ZStack {
            googleMap
            VStack {
                //searchTextBar
                //       .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                Spacer()
                numerScrollButtonSection
                confirmButtonSection
            }
        }
        
    }
    var googleMap : some View {
        GoogleMapViewForCreateStoryControllerBridge(confirmedMarker: $createChapterViewVM.markers,
                                      selectedMarker: $createChapterViewVM.selectedMarker,
                                      isMarkerWillRedrawing:$createChapterViewVM.isMarkerWillRedrawing,
                                      isGoogleMapSheetMode: $createChapterViewVM.isGoogleMapSheetMode,
                                      //This will set the selecetedPlace from the tap on the Google Map
                                      getPlaceFromTapOnMap:
                                           {newMarker, placeId in//Step1 get the info from the DidTap on the map
                                                        createChapterViewVM.setSelectedPlaceByTapAt(marker: newMarker, //Step2 set the selectedPlace
                                                        placeId: placeId){createChapterViewVM.placeForChapter = $0}}
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private var searchTextBar : some View {
        VStack(spacing:0){
            if createChapterViewVM.processStatus != .finish{
                
                HStack{
                    Button(action: {
                        withAnimation {
                            if createChapterViewVM.searchResultPlaces.count > 0  {
                                createChapterViewVM.isSearchResultListShow.toggle()
                            }
                        }
                    }, label: {
                        HStack(){
                            Image(systemName: "arrow.down")
                                .rotationEffect(Angle(degrees: createChapterViewVM.isSearchResultListShow ? 0 : 180))
                                .foregroundColor(createChapterViewVM.searchResultPlaces.count > 0 ? Color.blue : Color.gray)
                                .padding(10)
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(createChapterViewVM.searchText.isEmpty ? .gray : .black)
                            
                            TextField("find location for your story" ,text :$createChapterViewVM.searchText)
                            //                .textFieldStyle(.roundedBorder)
                                .keyboardType(.default)
                                .submitLabel(.done)
                                .onSubmit {
                                    // This will prevent search query with empty string
                                    if  !createChapterViewVM.searchDone() {
                                        self.searchTextInfocuse = true
                                    }
                                }
                                .disableAutocorrection(true)
                                .focused($searchTextInfocuse)
                                .onChange(of: createChapterViewVM.searchText, perform: { searchText in
                                    if searchText.count == 0 {
                                        createChapterViewVM.deleteSearchFieldAndResult()
                                    }
                                })
                                .padding(8)
                                .font(.headline)
                                .background(.thickMaterial)
                                .foregroundColor(.black)
                                .onTapGesture {
                                    createChapterViewVM.searchTextFieldTapped()
                                }
                            
                        }
                    })
                    Button(action: {
                        //delete search field and list
                        createChapterViewVM.deleteSearchFieldAndResult()
                        createChapterViewVM.isSearchResultListShow.toggle()
                        self.searchTextInfocuse = true
                        
                        
                    }, label: {
                        Image(systemName: "xmark")
                            .foregroundColor(createChapterViewVM.searchText.isEmpty ? .gray : .black)
                    })
                    .padding(10)
                }
                .background(.thickMaterial)
                .onAppear {
                    //keyboard will up and ready for new story only
                    if createChapterViewVM.chapters.count == 0{
                        DispatchQueue.main.asyncAfter(deadline: .now()  + 0.6) {
                            self.searchTextInfocuse = true
                        }
                    }
                }
            }
            
            if createChapterViewVM.isSearchResultListShow {
                Divider()
                //googleMapAPIPlace in here have no data of coordinate
                ForEach(createChapterViewVM.searchResultPlaces ){  googleMapAPIPlace in
                    VStack(alignment:.center) {
                        Button(action: {
                            //This method will make status as .selectLocation
                            createChapterViewVM.setCandidatePlaceFromSearchList(googleMapAPIPlace:googleMapAPIPlace){
                                //setMarkOnSearchList(googlePlace : googleMapAPIPlace)
                                // no toggle in here
                                self.searchTextInfocuse = false
                                
                                
                            }
                        }, label: {
                            GeometryReader{ geometry in
                                HStack(alignment: .center) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 2, trailing: 4))
                                    //This will do the red mark for the list that has been selected by user
                                        .foregroundColor(googleMapAPIPlace == createChapterViewVM.placeForChapter ? .red : .black)
                                        .font(.title)
                                    TextWithAttributedString(attributedString: textMatchHiglight(place: googleMapAPIPlace),
                                                             preferredMaxLayoutWidth: geometry.size.width - 40 ,dynamicHeight: $dynamicHeight)
                                    .fixedSize(horizontal:  false, vertical: true)
                                    .background(.thickMaterial)
                                }
                            }
                        })
                        Divider()
                    }
                }
                .font(.caption )
                .background(.thickMaterial)
                .frame(height: 43 )
            }
            
        }
        .background(.thickMaterial)
        .cornerRadius(10)
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
    }
    //set selectedMarker with  users selection from searchList
//    private func setMarkOnSearchList(googlePlace : GoogleMapAPIPlace? = nil) {
//        if let googlePlace = googlePlace{
//            createChapterViewVM.candidatePlaceFromSearchList = googlePlace   // for map reslut selection status
//        }
//    }
    
    private var numerScrollButtonSection : some View {
        ScrollView(.horizontal,showsIndicators: false){
            HStack(spacing:10){
                ForEach(createChapterViewVM.chapters.indices , id : \.self){ index in
                    Button {}
                label: {
                    VStack{
                        Image(systemName: "\(index+1).circle.fill")
                            .resizable()
                            .frame(width:35 , height: 35)
                            .foregroundColor(createChapterViewVM.selectedChapterIndex == index ? Color.orange : Color.red)
                            .withPressableStyle(scaledAmount: 0.3)
                            .overlay(getSmallFirstCategoryImage(categories:createChapterViewVM.chapters[index].categories), alignment: .topTrailing)
                        Text(createChapterViewVM.chapters[index].place.name ?? "No place Name")
                            .font(.system(size: 10, weight: .bold, design: .default))
                            .frame(maxWidth:70)
                            .lineLimit(1)
                            .foregroundColor(Color.black)
                    }
                    
                    
                    
                }
                .simultaneousGesture(
                    LongPressGesture()
                        .onEnded { _ in
                            //move  to index
                            createChapterViewVM.focusOnSelectedMarkerBy(atIndex: index)
                            deleteChapterIndex = index
                            print("delete deleteConfirmedLocation Index is \(deleteChapterIndex)")
                            activeSheet = .isShow_DeleteChapter_ActionSheet                                      }
                )
                .highPriorityGesture(
                    TapGesture()
                        .onEnded { _ in
                            print("move to \(index+1) place")
                            youtubeViewVM.startTime =  createChapterViewVM.chapters[index].youtubeTime
                            createChapterViewVM.focusOnSelectedMarkerBy(atIndex: index)
                        }
                )
                .padding(EdgeInsets(top: 3, leading: 10, bottom: 5, trailing: 3))
                }
            }
            
        }// end of scrollView\
        .animation(.easeInOut(duration: 1))
    }
    
    
    private var confirmButtonSection : some View {
        HStack(alignment: .center){
            //if user select location on the prediction list
            if createChapterViewVM.processStatus == .selectLocation {
                HStack {
                    Button {
                        if let confirmedPlace = createChapterViewVM.placeForChapter{
                   
                                //This is moment selectedPlace become confirmed place with number
                                createChapterViewVM.confirmSelectedPlace()
                                //after confirmed emphty the search text
                                //  addStoryMapViewVM.searchText = ""
                        }else{
                            print("fail to get confirmed place")
                        }
                    } label: {
                        Text("Confirm Location")
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(10)
                    .background(.orange)
                    .cornerRadius(10)
                    .withPressableStyle(scaledAmount: 0.9)
                    
                    Button {
                        createChapterViewVM.processStatus = .finish
                        createChapterViewVM.deleteMarkerAfterCancel()
                    } label: {
                        Text("Cancel")
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(10)
                    .background(.orange)
                    .cornerRadius(10)
                    .withPressableStyle(scaledAmount: 0.9)
                }
            }
            
            if createChapterViewVM.processStatus == .confirmLocation {
                //requre animation
                //                Button {
                //                    // would like to see all the location has been set on the map
                //                    createChapterViewVM.allLocationHasBeenSet()
                //                    youtubeViewVM.isSearchMode.toggle()
                //                    //presentationMode.wrappedValue.dismiss()
                //
                //                } label: {
                //                    Text("All Location has been set")
                //                        .foregroundColor(.white)
                //                        .font(.headline)
                //                        .padding(10)
                //                        .background(.orange)
                //                        .cornerRadius(10)
                //                        .withPressableStyle(scaledAmount: 0.9)
                //                }
                
            }
            
            if createChapterViewVM.processStatus == .finish  {
                //                Button {
                //                    //save and close the screen
                //                    createChapterViewVM.update()
                //                } label: {
                //                    Text("update")
                //                        .foregroundColor(.white)
                //                        .font(.headline)
                //                        .padding(10)
                //                        .background(.orange)
                //                        .cornerRadius(10)
                //                        .withPressableStyle(scaledAmount: 0.9)
                //                }
                
            }
            
        }
    }
    
    var youtubeView : some View {
        
        YoutubeView(youtubeViewVM: self.youtubeViewVM)
            .frame(height: 220 )
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1),radius: 46,x: 0,y: 15)
    }
    
    private var videoAndCategorySection : some View {
        VStack{
            youtubeView
            ScrollView(.horizontal){
                HStack{
                    ForEach(createChapterViewVM.getCategoryList(),id:\.self){ category in
                        Button {
                            //store category
                            if let index =  createChapterViewVM.chapterCategory.firstIndex(of: category){
                                createChapterViewVM.chapterCategory.remove(at: index)
                            }else{
                                createChapterViewVM.chapterCategory.append(category)
                            }
                        } label: {
                            if  createChapterViewVM.chapterCategory.contains(category){
                                Image(category.key)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.orange, lineWidth: 4)
                                    )
                                
                            }else{
                                Image(category.key)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(5)
                            }
                        }
                        
                    }
                }
            }
            
            
            HStack{
                Text(youtubeViewVM.getDisplayTime())
                    .foregroundColor(Color.orange)
                    .font(.system(size: 15, weight: .bold, design: .default))
                
                Spacer()
                
                Button {
                    print("Play!!!")
                    
                    youtubeViewVM.play()
                }label: {
                    Image(systemName: "play.rectangle")
                        .resizable()
                        .frame(width:30 , height: 30)
                        .foregroundColor(youtubeViewVM.youtubePlaysBackState == .playing ? Color.gray : Color.orange)
                }
                .disabled(youtubeViewVM.youtubePlaysBackState == .playing)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                
                Button {
                    print("Pause!!!")
                    youtubeViewVM.pause()
                    
                }label: {
                    Image(systemName: "pause.rectangle")
                        .resizable()
                        .frame(width:30 , height: 30)
                        .foregroundColor(youtubeViewVM.youtubePlaysBackState != .playing  ? Color.gray : Color.orange)
                }
                .disabled(youtubeViewVM.youtubePlaysBackState != .playing)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                
                Button {
                    // check the validate
                    //1 category selection
                    //2 mapping location
                    //pop category
                    
                    if validateForNewChapter(){
                        //set the time for selected Place first
                        createChapterViewVM.placeForChapter?.youtubeTime = youtubeViewVM.currentTime ?? 0
                        confirmChapterModalData = ConfirmChapterModalData(createChapterViewVM:createChapterViewVM)
                        isCreateChapterModal = true
                    }else{
                        activeSheet = .isShow_FailAddchapter_ActionSheet
                    }
                    
                    
                }label: {
                    if youtubeViewVM.youtubePlaysBackState != .paused {
                        
                        Image(systemName: "bookmark.slash.fill")
                            .resizable()
                            .frame(width:30 , height: 30)
                            .foregroundColor(Color.gray)
                    }else{
                        Image(systemName: "bookmark.fill")
                            .resizable()
                            .frame(width:30 , height: 30)
                            .foregroundColor(Color.orange)
                    }
                }
                .disabled(youtubeViewVM.youtubePlaysBackState != .paused)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                
                
                
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            
        }
    }
    
    
    func segueForSearchMapSheet(){
        createChapterViewVM.isGoogleMapSheetMode = true
        searchMapSheetData = GoogleMapSheetViewData(createChapterViewVM: createChapterViewVM)
        
    }
    
    func validateForNewChapter() -> Bool{
        var isValidate = false
        //its actually useless
        if  createChapterViewVM.placeForChapter != nil
            &&  createChapterViewVM.chapterCategory.count > 0 {
            isValidate = true
        }
        return isValidate
    }
    
    func getSmallFirstCategoryImage(categories : [Category])  -> some View {
        HStack{
            if let firstCategory =  categories.first {
                Image(firstCategory.key)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .cornerRadius(3)
            }else{
                //Empty View
                EmptyView()
            }
            
        }
        .padding([.top,.leading],5)
        .offset(y:-10)
    }
    
    func textMatchHiglight( place: GoogleMapAPIPlace) -> NSMutableAttributedString {
        let regularFont = UIFont.systemFont(ofSize: UIFont.labelFontSize)
        let boldFont = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        
        
        let resultsStr = place.fullName?.mutableCopy() as! NSMutableAttributedString
        
        /// Every text range that matches the user input has an attribute, kGMSAutocompleteMatchAttribute.
        ///  You can use this attribute to highlight the matching text in the user's query
        resultsStr.enumerateAttribute(NSAttributedString.Key.gmsAutocompleteMatchAttribute,
                                      in: NSMakeRange(0, resultsStr.length),
                                      options: []) {
            (value, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            let font = (value == nil) ? regularFont : boldFont
            resultsStr.addAttribute(NSAttributedString.Key.font, value: font, range: range)
        }
        return resultsStr
        
        
    }
    
}

struct CreateChapterView_Previews: PreviewProvider {
    static var previews: some View {
        CreateChapterView(youtubeViewVM: YoutubeViewVM(videoId: dev.youtubeContentItems.first!.contentDetails.videoId,
                                                       videoTitle: dev.youtubeContentItems.first!.snippet.title),
                          createChapterViewVM: dev.addStoryViewVM.createChapterViewVM,
                          selectedIndex: 1)
        
    }
}
