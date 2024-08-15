//
//  Season.swift
//  Hidive
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

@Observable
class Season: Codable, Equatable, Hashable, Identifiable, Episodable, Savable {
    let id: Int
    let title: String
    let description: String
    let longDescription: String
    var smallCoverUrl: ThumbnailEntry?
    var coverUrl: ThumbnailEntry?
    var titleUrl: ThumbnailEntry?
    var posterUrl: ThumbnailEntry?
    var seasonNumber: Int
    let episodeCount: Int
    let series: Series?
    var episodes: [Episode]?
    let paging: Paging?
    
    var parentTitle: String {
        return series?.title ?? title
    }
    
    var parentId: Int {
        return series?.id ?? id
    }
    
    var isSaved: Bool {
        return episodes?.allSatisfy { $0.isSaved } ?? true
    }
    
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
        case paging
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.longDescription = try container.decode(String.self, forKey: .longDescription)
        self.smallCoverUrl = try container.decodeIfPresent(ThumbnailEntry.self, forKey: .smallCoverUrl)
        self.coverUrl = try container.decodeIfPresent(ThumbnailEntry.self, forKey: .coverUrl)
        self.titleUrl = try container.decodeIfPresent(ThumbnailEntry.self, forKey: .titleUrl)
        self.posterUrl = try container.decodeIfPresent(ThumbnailEntry.self, forKey: .posterUrl)
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber) ?? 1
        self.episodeCount = try container.decode(Int.self, forKey: .episodeCount)
        self.series = try container.decodeIfPresent(Series.self, forKey: .series)
        self.episodes = try container.decodeIfPresent([Episode].self, forKey: .episodes)
        self.paging = try container.decodeIfPresent(Paging.self, forKey: .paging)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.description, forKey: .description)
        try container.encode(self.longDescription, forKey: .longDescription)
        try container.encodeIfPresent(self.smallCoverUrl, forKey: .smallCoverUrl)
        try container.encodeIfPresent(self.coverUrl, forKey: .coverUrl)
        try container.encodeIfPresent(self.titleUrl, forKey: .titleUrl)
        try container.encodeIfPresent(self.posterUrl, forKey: .posterUrl)
        try container.encode(self.seasonNumber, forKey: .seasonNumber)
        try container.encode(self.episodeCount, forKey: .episodeCount)
        try container.encodeIfPresent(series, forKey: .series)
        try container.encodeIfPresent(self.episodes, forKey: .episodes)
        try container.encodeIfPresent(self.paging, forKey: .paging)
    }
    
    static func == (lhs: Season, rhs: Season) -> Bool {
        return lhs.id == rhs.id && lhs.episodes == rhs.episodes
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(episodes)
    }
    
    func saveThumbnails() async {
        self.smallCoverUrl = await smallCoverUrl?.save()
        self.coverUrl = await coverUrl?.save()
        self.titleUrl = await titleUrl?.save()
        self.posterUrl = await posterUrl?.save()
        for episode in episodes ?? [] {
            await episode.saveThumbnails()
        }
    }
}
