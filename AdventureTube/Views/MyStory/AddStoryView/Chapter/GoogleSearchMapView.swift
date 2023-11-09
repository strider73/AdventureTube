//
//  GoogleSearchMapView.swift
//  AdventureTube
//
//  Created by chris Lee on 7/7/2022.
//

import SwiftUI

struct GoogleMapSheetViewData : Identifiable {
    var id = UUID()
    var createChapterViewVM : CreateChapterViewVM
//    {
//        didSet{
//            if createChapterViewVM.selectedMarker == nil{
//                
//            }
//        }
//    }
}

struct GoogleSearchMapView<Content:View>: View {
    @Environment(\.presentationMode) var presentationMode
    
    let content :Content
    @ObservedObject var createChapterViewVM  : CreateChapterViewVM
    @FocusState private var searchTextInfocuse : Bool
    @State private var deleteConfirmedLocationIndex : Int = -1
    @State var activeSheet : CreateChapterViewActiveSheet?
    
    
    @State private var dynamicHeight: CGFloat = .zero
    
    
    init(createChapterViewVM :CreateChapterViewVM , @ViewBuilder content :@escaping () -> Content){
        print("GoogleSearchMapView ~~~~")
        self.content = content()
        self.createChapterViewVM = createChapterViewVM
        
    }
    
    var body: some View {
        
        ZStack{
            
            content.edgesIgnoringSafeArea(.all)
            VStack {
                ZStack{
                    Capsule()
                        .frame(width: 40, height: 6)
                }
                .frame(height:13)
                .frame(maxWidth:.infinity)
                .background(Color.white.opacity(0.00001))
                
                searchTextBar
                    .onAppear{
                        //createChapterViewVM.processStatus = .searchLocation
                    }
                Spacer()
                numerScrollButtonSection
                confirmButtonSection
                
            }
        }
        .onDisappear {
            createChapterViewVM.isGoogleMapSheetMode = false
        }
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
                
                ForEach(createChapterViewVM.searchResultPlaces ){  adventureTubePlace in
                    VStack(alignment:.center) {
                        Button(action: {
                            //This method will make status as .selectLocation
                            createChapterViewVM.setCandidatePlaceFromSearchList(googleMapAPIPlace:adventureTubePlace){
                                //setMarkOnSearchList(googlePlace : adventureTubePlace)
                                // no toggle in here
                                self.searchTextInfocuse = false
                                
                                
                            }
                        }, label: {
                            GeometryReader{ geometry in
                                HStack(alignment: .center) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 2, trailing: 4))
                                    //This will do the red mark for the list that has been selected by user
                                        .foregroundColor(adventureTubePlace == createChapterViewVM.placeForChapter ? .red : .black)
                                        .font(.title)
                                    TextWithAttributedString(attributedString: textMatchHiglight(place: adventureTubePlace),
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
    //    //set selectedMarker with  users selection from searchList
    //    private func setMarkOnSearchList(googlePlace : GoogleMapAPIPlace? = nil) {
    //        if let googlePlace = googlePlace{
    //            createChapterViewVM.selectedPlace = googlePlace   // for map reslut selection status
    //        }
    //    }
    
    private var numerScrollButtonSection : some View {
        ScrollView(.horizontal){
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
                            .frame(maxWidth:50)
                            .lineLimit(1)
                            .foregroundColor(Color.black)
                    }
                    
                }
                .simultaneousGesture(
                    LongPressGesture()
                        .onEnded { _ in
                            //move  to index
                            createChapterViewVM.focusOnSelectedMarkerBy(atIndex: index)
                            deleteConfirmedLocationIndex = index
                            print("delete deleteConfirmedLocation Index is \(deleteConfirmedLocationIndex)")
                            activeSheet = .isShow_DeleteChapter_ActionSheet                                      }
                )
                .highPriorityGesture(
                    TapGesture()
                        .onEnded { _ in
                            print("move to \(index+1) place")
                            createChapterViewVM.selectedChapterIndex = index
                            //youtubeViewVM.startTime =  createChapterViewVM.confirmedPlaces[selectedIndex].youtubeTime
                            createChapterViewVM.focusOnSelectedMarkerBy(atIndex: index)
                        }
                )
                .padding()
                }
            }
            
        }// end of scrollView
    }
    
    
    private var confirmButtonSection : some View {
        HStack(alignment: .center){
            //if user select location on the prediction list
            if createChapterViewVM.processStatus == .selectLocation {
                HStack {
                    Button {
                        if let confirmedPlace = createChapterViewVM.placeForChapter{
                            //check the sample place first
                            
                            createChapterViewVM.confirmSelectedPlace()
                            presentationMode.wrappedValue.dismiss()
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
                        
                        presentationMode.wrappedValue.dismiss()
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
}

struct GoogleSearchMapView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleSearchMapView( createChapterViewVM :dev.addStoryViewVM.createChapterViewVM ){
            EmptyView()
        }
    }
}
