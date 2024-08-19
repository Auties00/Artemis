//
//  Paging.swift
//   Artemis
//
//  Created by Alessandro Autiero on 25/07/24.
//

import Foundation

struct Paging : Codable, Equatable, Hashable {
    let moreDataAvailable: Bool
    let lastSeen: String

    enum CodingKeys: CodingKey {
        case moreDataAvailable
        case lastSeen
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.moreDataAvailable = try container.decode(Bool.self, forKey: .moreDataAvailable)
        if let lastSeenString = try? container.decode(String.self, forKey: .lastSeen) {
            self.lastSeen = lastSeenString
        } else if let lastSeenInt = try? container.decode(Int.self, forKey: .lastSeen) {
            self.lastSeen = "\(lastSeenInt)"
        }else {
            self.lastSeen = ""
        }
    }
}
