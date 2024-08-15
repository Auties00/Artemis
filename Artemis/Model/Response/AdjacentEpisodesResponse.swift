//
//  AdjacentEpisodesResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 25/07/24.
//

import Foundation

struct AdjacentEpisodesResponse: Decodable {
    let preceding: [Episode]?
    let following: [Episode]?
    
    enum CodingKeys: CodingKey {
        case precedingVods
        case followingVods
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.preceding = try container.decodeIfPresent([Episode].self, forKey: .precedingVods)
        self.following = try container.decodeIfPresent([Episode].self, forKey: .followingVods)
    }
}
