//
//  GeneralResponse.swift
//  Artemis
//
//  Created by Alessandro Autiero on 12/08/24.
//

import Foundation

struct GeneralResponse: Decodable {
    let code: Int?
    let message: String?
}
