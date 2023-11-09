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

//struct YoutubePopLoadingView: View {
//
//
//    var youtubeViewVM : YoutubeViewVM?
//    var addStoryMapViewVM : AddStoryMapViewVM
//    var place :ATGooglePlace?
//
//
//    var body: some View {
//        ZStack{
//            if let youtubeViewVM = youtubeViewVM , let place = place{
//                YoutubePopView(youtubeViewVM: youtubeViewVM,
//                               addStoryMapViewVM : addStoryMapViewVM,
//                               place: place)
//            }
//        }
//    }
//
//}

struct PlayChapterData : Identifiable {
    var id: String{
        return youtubeViewVM.videoId
    }
   
    var youtubeViewVM : YoutubeViewVM
    var createChapterViewVM : CreateChapterViewVM
    var place : Binding<GoogleMapAPIPlace>
    var categorySelection : [Category] = []
    var adventureTubeData : AdventureTubeData?
    var selectedIndex : Int
}

struct PlayChapterView: View {
    @ObservedObject var youtubeViewVM : YoutubeViewVM
    @ObservedObject var createChapterViewVM  : CreateChapterViewVM
    @Environment(\.presentationMode) var presentationMode
    @Binding  var place : GoogleMapAPIPlace
    @State private var selectedPlace : GoogleMapAPIPlace?

    @State var currentTime  = 0
    @State var placeContentCategory : [Category]  = [] // This is Category for the Location
    @State var currentStoryLocationIndex : Int = 0
    
    var categorySelection : [Category]
    var adventureTubeData : AdventureTubeData?
    init(youtubeViewVM :  YoutubeViewVM ,
         createChapterViewVM : CreateChapterViewVM ,
         categorySelection : [Category] , // This category is about story not the location
         place : Binding<GoogleMapAPIPlace>,
         selectedIndex : Int ,
         adventureTubeData : AdventureTubeData?){
        self.youtubeViewVM = youtubeViewVM
        self.createChapterViewVM = createChapterViewVM
        self.adventureTubeData = adventureTubeData
        self.categorySelection = categorySelection
        
        _currentStoryLocationIndex = State(wrappedValue: selectedIndex)
        _place = place
        
        //setting placeContentCategory
        _placeContentCategory = State(wrappedValue: place.contentCategories.wrappedValue)
        
    }
    
    var body: some View {
        ZStack {
            ColorConstant.background.color.edgesIgnoringSafeArea(.all)
            VStack {
                HStack{
                    Spacer()
                    Text(place.name)
                        .foregroundColor(Color.black)
                        .font(.headline)
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    }label: {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .frame(width:30 , height: 30)
                            .foregroundColor(Color.orange)
                    }
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                }
                YoutubeView(youtubeViewVM: self.youtubeViewVM)
                    .frame(height: 220 )
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1),radius: 46,x: 0,y: 15)
                //selected Category if they've saved in coredata already
                if let  categorySelection = categorySelection {
                    /*
                     
                     case with coredata
                     
                     1) it will display all contentCatory for Story
                     2) mark only category relate to the location
                     */
                    ScrollView(.horizontal){
                        HStack{
                            ForEach(categorySelection , id :\.self){ category in
                                Button {
                                    // mapping with location
                                    if let index = placeContentCategory.firstIndex(of: category){
                                        placeContentCategory.remove(at:index)
                                    }else{
                                        placeContentCategory.append(category)
                                    }
                                } label: {
                                    if placeContentCategory.contains(category){
                                        Text(category.key)
                                            .categoryIcon(isSelected: true)
                                    }else{
                                        Text(category.key)
                                            .categoryIcon(isSelected: false)
                                    }
                                }
                            }
                            
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                }
                
                // if category selected but not yet saved
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
 
                    
                }
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                
                ZStack {
                    
                    GoogleMapViewControllerBridge(confirmedMarker: $createChapterViewVM.markers,
                                                  selectedMarker: $createChapterViewVM.selectedMarker,
                                                  isMarkerWillRedrawing: $createChapterViewVM.isMarkerWillRedrawing,
                                                  isGoogleMapSheetMode: $createChapterViewVM.isGoogleMapSheetMode,

                                                  getPlaceFromTapOnMap: {
                                                    newMarker, placeId in
                                                    createChapterViewVM.setSelectedPlaceByTapAt(marker: newMarker,
                                                                                                placeId: placeId)
                                                {self.selectedPlace = $0}})
                    
                    
                    
                    VStack {
                        Spacer()
                        numberScrollButtonSection
                    }
                }
            }
            
        }
        .onAppear(){
            self.currentTime = 0
        }
        //        .padding(6)
        //        .background(Color.gray.opacity(0.85))
        //        .cornerRadius(10)
    }
    
    
    private var numberScrollButtonSection : some View {
        ScrollView(.horizontal){
            HStack(spacing:10){
                ForEach(createChapterViewVM.chapters.indices , id : \.self){ index in
                    Button {}
                label: {
                    Image(systemName: "\(index+1).circle.fill")
                        .resizable()
                        .frame(width:35 , height: 35)
                        .foregroundColor(currentStoryLocationIndex == index ? Color.orange :  Color.red)
                        .withPressableStyle(scaledAmount: 0.3)
                    
                }
                    
                .highPriorityGesture(
                    TapGesture()
                        .onEnded { _ in
                            print("move to \(index+1) place")
                            
                            // This is crucial to avoid index out of range error
                            // in case  location has been added mutiple time after first save
                            if let adventureTubeData = self.adventureTubeData{
                                
                                if adventureTubeData.places.count >= index+1{
                                    youtubeViewVM.startTime =  adventureTubeData.places[index].youtubeTime
                                }
                            }
                            currentStoryLocationIndex = index
                            createChapterViewVM.focusOnSelectedMarkerBy(atIndex: index)
                            
                        }
                    
                )
                .padding()
                }
            }
        }

    }
    

    

    
}

struct YoutubePopView_Previews: PreviewProvider {
    static var previews: some View {
        PlayChapterView(youtubeViewVM: YoutubeViewVM(videoId: dev.youtubeContentItems.first!.contentDetails.videoId, startTime: 100),
                       createChapterViewVM: dev.addStoryViewVM.createChapterViewVM,
                       categorySelection: dev.addStoryViewVM.categorySelection,
                       place: .constant(dev.addStoryViewVM.places[0]),
                       selectedIndex: 0,
                       adventureTubeData: dev.youtubeContentItems.first!.snippet.adventureTubeData)
        
    }
}
