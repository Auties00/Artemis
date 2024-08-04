//
//  DRMResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 19/07/24.
//

import Foundation

struct DRMResponse: Decodable {
    let response: Data
    
    enum CodingKeys: CodingKey {
        case response
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base64Data = try container.decode(String.self, forKey: .response)
        self.response = Data(base64Encoded: base64Data.data(using: .utf8)!)!
    }
}
