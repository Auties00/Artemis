//
//  Series.swift
//  Hidive
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

struct Series : Decodable, Equatable, Hashable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let longDescription: String
    let smallCoverUrl: String?
    let coverUrl: String?
    let seasons: [Season]?
    let rating: ContentRating?
    let contentRating: ContentRating?
    let seasonCount: Int
    
    enum CodingKeys: CodingKey {
        case id
        case seriesId
        case title
        case description
        case longDescription
        case smallCoverUrl
        case coverUrl
        case seasons
        case rating
        case contentRating
        case seasonCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        print("_")
        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? container.decode(Int.self, forKey: .seriesId)
        print("id")
        self.title = try container.decode(String.self, forKey: .title)
        print("title")
        self.description = try container.decode(String.self, forKey: .description)
        print("description")
        self.longDescription = try container.decode(String.self, forKey: .longDescription)
        print("longDescription")
        self.smallCoverUrl = try container.decodeIfPresent(String.self, forKey: .smallCoverUrl)
        print("smallCoverUrl")
        self.coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)
        print("coverUrl")
        self.seasons = try container.decodeIfPresent([Season].self, forKey: .seasons)
        print("seasons")
        self.rating = try container.decodeIfPresent(ContentRating.self, forKey: .rating)
        print("rating")
        self.contentRating = try container.decodeIfPresent(ContentRating.self, forKey: .contentRating)
        print("contentRating")
        self.seasonCount = try container.decodeIfPresent(Int.self, forKey: .seasonCount) ?? 1
        print("seasonCount")
    }
}
