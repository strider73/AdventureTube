//
//  LoginServiceProtocol.swift
//  AdventureTube
//
//  Created by chris Lee on 21/1/22.
//

import Foundation
protocol LoginServiceProtocol {
    
    func signIn(completion:@escaping(_ userData :(Result<UserModel,Error>)) -> ())
    
    func signOut()
    
    func addMoreScope(completion : @escaping () -> Void)
    
    func disconnectAdditionalScope()
}
