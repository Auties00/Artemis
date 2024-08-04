//
//  DRMRequest.swift
//  Hidive
//
//  Created by Alessandro Autiero on 19/07/24.
//

import Foundation

struct DRMChallengeRequest: Encodable {
    let challenge: String
}

struct DRMInfoRequest: Encodable {
    let system: String
    let keyIds: [String]?
    
    enum CodingKeys: CodingKey {
        case system
        case key_ids
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.system, forKey: .system)
        try container.encodeIfPresent(self.keyIds, forKey: .key_ids)
    }
}
