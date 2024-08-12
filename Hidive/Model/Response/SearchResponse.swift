//
//  SearchResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import Foundation

struct SearchResponse: Decodable, Hashable {
    let results: [SearchEntry]
    
    private enum CodingKeys: CodingKey {
        case results
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try container.decode([SearchResult].self, forKey: .results).flatMap { $0.hits }
    }
}

private struct SearchResult: Decodable {
    let hits: [SearchEntry]
}

struct SearchEntry: Decodable, Identifiable, Hashable {
    let type: String
    let weight: Float
    let id: Int
    let name: String
    let description: String
    let coverUrl: String
    let smallCoverUrl: String
    let seasonsCount: Int?
    let videosCount: Int?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
