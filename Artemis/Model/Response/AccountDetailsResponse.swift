//
//  AccountDetailsResponse.swift
//   Artemis
//
//  Created by Alessandro Autiero on 03/08/24.
//

import Foundation

struct AccountDetailsResponse: Decodable {
    let name: AccountName?
    let id: String
    let contactEmail: String
    let createdDate: Int
}

struct AccountName: Decodable {
    let fullName: String?
}
