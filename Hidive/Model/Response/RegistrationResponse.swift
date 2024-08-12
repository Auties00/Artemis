//
//  RegistrationResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 03/08/24.
//

import Foundation

struct RegistrationResponse: Decodable {
    let status: Int?
    let code: String?
    let authorisationToken: String?
    let refreshToken: String?
}
