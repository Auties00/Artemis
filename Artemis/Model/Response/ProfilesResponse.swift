//
//  ProfilesResponse.swift
//   Artemis
//
//  Created by Alessandro Autiero on 03/08/24.
//

import Foundation

struct ProfilesResponse: Decodable {
    let items: [Profile]
    let flow: String
    let pinProtection: String
}
