//
//  DRMResponse.swift
//   Artemis
//
//  Created by Alessandro Autiero on 19/07/24.
//

import Foundation

struct DRMResponse: Decodable {
    let response: Data
    let duration: Int
    let persistence: Bool
    
    enum CodingKeys: CodingKey {
        case response
        case duration
        case persistence
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base64Data = try container.decode(String.self, forKey: .response)
        self.response = Data(base64Encoded: base64Data.data(using: .utf8)!)!
        self.duration = try container.decode(Int.self, forKey: .duration)
        self.persistence = try container.decode(Bool.self, forKey: .persistence)
    }
}
