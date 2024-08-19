//
//  ActivateProfileRequest.swift
//   Artemis
//
//  Created by Alessandro Autiero on 11/08/24.
//

import Foundation

struct ActivateProfileRequest: Encodable {
    let profileId: String
    let pin: String?
    
    enum CodingKeys: String, CodingKey {
        case profileId = "profile-id"
        case pin
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.profileId, forKey: .profileId)
        try container.encodeIfPresent(self.pin, forKey: .pin)
    }
}
