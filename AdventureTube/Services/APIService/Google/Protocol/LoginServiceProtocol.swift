//
//  LoginServiceProtocol.swift
//  AdventureTube
//
//  Created by chris Lee on 21/1/22.
//

import Foundation
import GoogleSignIn
protocol LoginServiceProtocol {
    
    func signIn(completion:@escaping(_ userData :(Result<UserModel,Error>)) -> ())
    
    
    func restorePreviousSignIn(completion:@escaping(_ reesult:(Result<UserModel,Error>)) -> ())
    
    func signOut(completion: @escaping (_ result: Result<Void, Error>) -> Void)

    func addMoreScope(completion : @escaping (Error?) -> Void)
    
    func disconnectAdditionalScope()
}
