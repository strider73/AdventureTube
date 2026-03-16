//
//  AddStoryViewVM+Validation.swift
//  AdventureTube
//
//  Created by chris Lee on 29/3/22.
//

import Foundation

extension AddStoryViewVM {

    func validateForCreateChaptor(completion : (Bool) -> ()){
        do{
            try validaterExceptLocation()
            completion(isShowErrorMessage)
        }catch{
            print("there is error \(error.localizedDescription)")
            isShowErrorMessage = true
            completion(isShowErrorMessage)
            errorMessage = error.localizedDescription
        }
    }

    func validaterAllContentsBeforeStoreToCoreData() throws{
        //        guard categorySelection.count > 0 else{
        //            throw SaveError.needActivityType
        //        }

        guard durationSelection != .select else{
            throw SaveError.needTriopDuration
        }

        guard  videoTypeSelection != .select  else{
            throw SaveError.needVideoType
        }

        //        guard confirmedPlaces.count > 0 else{
        //            throw SaveError.needLocationData
        //        }
        //
        //       try confirmedPlaces.map { place in
        //            guard place.youtubeTime != 0 else{
        //                throw SaveError.needMatchLocationWithTime(location: place.name)
        //            }
        //        }
    }

    func validaterExceptLocation() throws{
        //        guard categorySelection.count > 0 else{
        //            throw SaveError.needActivityType
        //        }

        guard durationSelection != .select else{
            throw SaveError.needTriopDuration
        }

        guard  videoTypeSelection != .select  else{
            throw SaveError.needVideoType
        }
    }
}
