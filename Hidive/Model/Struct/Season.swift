//
//  Season.swift
//  Hidive
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

struct Season: Decodable, Equatable, Hashable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let longDescription: String
    let smallCoverUrl: String
    let coverUrl: String
    let titleUrl: String
    let posterUrl: String?
    var seasonNumber: Int
    let episodeCount: Int
    let series: Series?
    let episodes: [Episode]?
    
    enum CodingKeys: CodingKey {
        case id
        case title
        case description
        case longDescription
        case smallCoverUrl
        case coverUrl
        case titleUrl
        case posterUrl
        case seasonNumber
        case episodeCount
        case series
        case episodes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        print("id")
        self.title = try container.decode(String.self, forKey: .title)
        print("title")
        self.description = try container.decode(String.self, forKey: .description)
        print("description")
        self.longDescription = try container.decode(String.self, forKey: .longDescription)
        print("longDescription")
        self.smallCoverUrl = try container.decode(String.self, forKey: .smallCoverUrl)
        print("smallCoverUrl")
        self.coverUrl = try container.decode(String.self, forKey: .coverUrl)
        print("coverUrl")
        self.titleUrl = try container.decode(String.self, forKey: .titleUrl)
        print("titleUrl")
        self.posterUrl = try container.decodeIfPresent(String.self, forKey: .posterUrl)
        print("posterUrl")
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber) ?? 1
        print("seasonNumber")
        self.episodeCount = try container.decode(Int.self, forKey: .episodeCount)
        print("episodeCount")
        self.series = try container.decodeIfPresent(Series.self, forKey: .series)
        print("series")
        self.episodes = try container.decodeIfPresent([Episode].self, forKey: .episodes)
        print("episodes")
    }
}
