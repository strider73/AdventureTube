//
//  ConfirmChapterView.swift
//  AdventureTube
//
//  Created by chris Lee on 8/7/2022.
//

import SwiftUI

struct ConfirmChapterView: View {

    @ObservedObject var createChapterViewVM : CreateChapterViewVM
    @Binding var isShowing:Bool
    
    var body: some View {
        VStack{
            Text("You are createing new chapter ")
                .padding(EdgeInsets(top: 15, leading: 40, bottom: 0, trailing:40))
            ZStack{
                VStack {
                    VStack(alignment: .leading) {
                        VStack {
                            HStack{
                                Image(systemName: "mappin.and.ellipse")
                                    .resizable()
                                    .frame(width:30 , height: 30)
                                    .foregroundColor(Color.black)
                                Text("Place name for This Chapter ")
                            }
                            if let place = createChapterViewVM.placeForChapter{
                                Text(place.name)
                            }
                        }
                        
                        VStack {
                            HStack{
                                Image(systemName: "clock")
                                    .resizable()
                                    .frame(width:30 , height: 30)
                                    .foregroundColor(Color.black)
                                Text("Time for this Chapter")
                            }
                            if let place = createChapterViewVM.placeForChapter{
                                Text(TimeToString.getDisplayTime( place.youtubeTime))
                            }
                        }
                        
                        VStack {
                            HStack{
                                Image(systemName: "square.grid.3x3.fill")
                                    .resizable()
                                    .frame(width:30 , height: 30)
                                    .foregroundColor(Color.black)
                                Text("Activities for this Chapter")
                            }
                        }
                    }
                    HStack(alignment:.center) {
                        if(createChapterViewVM.chapterCategory.count<6){
                            HStack{
                                ForEach(createChapterViewVM.chapterCategory, id: \.self){ category in
                                    Image(category.key)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(5)
                                }
                            }
                        }else{
                            
                            ScrollView(.horizontal){
                                HStack {
                                    ForEach(createChapterViewVM.chapterCategory, id: \.self){ category in
                                        Image(category.key)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                            .cornerRadius(5)
                                    }
                                }
                                .frame(width:400)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(5)
                
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 5)
            )
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            
            HStack{
                Button{
                    //Store all data to the coredata
                    createChapterViewVM.createNewChapter()
                    isShowing = false
                } label: {
                    Text("Confirm")
                }
                .foregroundColor(.white)
                .font(.headline)
                .padding(10)
                .background(.orange)
                .cornerRadius(10)
                .withPressableStyle(scaledAmount: 0.9)
                
                Button{
                    isShowing = false
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
    }
}

struct ConfirmChapterView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmChapterView(createChapterViewVM: dev.addStoryViewVM.createChapterViewVM, isShowing: .constant(true))
    }
}
