//
//  MapService.swift
//  AdventureTube
//
//  Created by chris Lee on 4/4/22.
//

import Foundation
import GooglePlaces
import GoogleMaps

class GoogleMapAndPlaceAPIService  {
    
    var placeClient : GMSPlacesClient
    let token : GMSAutocompleteSessionToken
    
    init(){
        GMSServices.provideAPIKey(YoutubeAPIService.API_KEY)  // for GoogleMaps
        GMSPlacesClient.provideAPIKey(YoutubeAPIService.API_KEY) //GooglePlaces
        placeClient = GMSPlacesClient.shared()
        /**
         * Create a new session token. Be sure to use the same token for calling
         * findAutocompletePredictions, as well as the subsequent place details request.
         * This ensures that the user's query and selection are billed as a single session.
         */
        token =  GMSAutocompleteSessionToken.init()
    }
    
    /// Google PlaceAPI
    func autoCompletePrediction(fromQuery :String ,
                                filter: GMSAutocompleteFilter ,
                                completion :@escaping ([GMSAutocompletePrediction]) -> () )
    {
        placeClient.findAutocompletePredictions(fromQuery: fromQuery, filter: filter, sessionToken: token)
        { results, error in
            print("findAutocompletePredictions  start")
            guard let autoCompletedplaces = results else {
                print("Autocomplete Error  \(String(describing: error))" )
                return
            }
            
            if(autoCompletedplaces.count == 0 ){
                print("there is no result for this search ")
            }else{
                completion(autoCompletedplaces)
            }
            
        }
    }
    
    
    /**
     Place details
     The GMSPlace class provides information about a specific place. You can get hold of a GMSPlace object in the following ways:
     
     Call GMSPlacesClient fetchPlaceFromPlaceID:, passing a GMSPlaceField, a place ID, and a callback method.
     
     When you request a place, you must specify which types of place data to return. To do this, pass a GMSPlaceField,
     GMSPlaceFieldCoordinate
     MSPlaceFieldOpeningHours
     GMSPlaceFieldPhoneNumber
     GMSPlaceFieldFormattedAddress
     GMSPlaceFieldWebsite
     
     The GMSPlace class can contain the following place data:
     
     name – The place's name.
     placeID – The textual identifier for the place. Read more about place IDs in the rest of this page.
     coordinate – The geographical location of the place, specified as latitude and longitude coordinates.
     
     businessStatus – The operational status of the place, if it is a business. It can contain one of the following values:
     GMSBusinessStatusOperational,
     GMSBusinessStatusClosedTemporarily,
     GMSBusinessStatusClosedPermanently,
     GMSBusinessStatusUnknown.
     
     phoneNumber – The place's phone number, in international format.
     
     */
    
    
    //get Name and Coordinate only 
    func getPlaceFieldCoordinate(placeId:String , completion:@escaping(GMSPlace) ->()){
        
        // Specify the place data types to return.
        let fields: GMSPlaceField =
        GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue)|UInt(GMSPlaceField.coordinate.rawValue)|UInt(GMSPlaceField.plusCode.rawValue)|UInt(GMSPlaceField.website.rawValue)|UInt(GMSPlaceField.types.rawValue))
        
        
        placeClient.fetchPlace(fromPlaceID: placeId,
                               placeFields: fields,
                               sessionToken: nil, callback: {
            (place: GMSPlace?, error: Error?) in
            if let error = error {
                print("An error occurred: \(error.localizedDescription)")
                return
            }
            if let place = place {
                completion(place)
            }
        })
    }
    
    
    /// Google Map API
}
