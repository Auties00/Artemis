//
//  WatchHistoryResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 27/07/24.
//

import Foundation

struct WatchHistoryResponse: Decodable {
    var episodes: [Episode]
    let page: Int
    let totalResults: Int
    let resultsPerPage: Int
    let totalPages: Int
    
    enum CodingKeys: CodingKey {
        case vods
        case page
        case totalResults
        case resultsPerPage
        case totalPages
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.episodes = try container.decode([Episode].self, forKey: .vods)
        self.page = try container.decode(Int.self, forKey: .page)
        self.totalResults = try container.decode(Int.self, forKey: .totalResults)
        self.resultsPerPage = try container.decode(Int.self, forKey: .resultsPerPage)
        self.totalPages = try container.decode(Int.self, forKey: .totalPages)
    }
}
