//
//  LoginResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import Foundation

struct LoginResponse : Decodable {
    let status: Int?
    let code: String?
    let authorisationToken: String?
    let refreshToken: String?
    let missingInformationStatus: String?
}
