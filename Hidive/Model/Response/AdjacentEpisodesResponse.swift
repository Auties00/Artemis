//
//  AdjacentVodsResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 25/07/24.
//

import Foundation

class AdjacentVodsResponse: Decodable {
    let precedingVods: [Vod]?
    let followingVods: [Vod]?
}
