//
//  Playlist.swift
//   Artemis
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

class Playlist: Codable, Equatable, Hashable, Identifiable, Episodable, Savable {
    let description: String
    let duration: Int?
    let title: String
    let offlinePlaybackLanguages: [String]?
    let favourite: Bool?
    var coverUrl: ThumbnailEntry?
    let id: Int
    let accessLevel: String?
    let playerURLCallback: String?
    let externalAssetID: String?
    let maxHeight: Int?
    let thumbnailsPreview: String?
    let longDescription: String
    let rating: Rating?
    let episodeInformation: EpisodeInformation?
    let categories: [String]?
    let onlinePlayback: String?
    var episodes: [Episode]?
    var episodesCount: Int
    let paging: Paging?
    
    var posterUrl: ThumbnailEntry? {
        return episodes?.first?.posterUrl
    }
    
    var parentTitle: String {
        return title
    }
    
    var parentId: Int {
        return id
    }
    
    var isSaved: Bool {
        return episodes?.allSatisfy { $0.isSaved } ?? true
    }
    
    enum CodingKeys: CodingKey {
        case description
        case duration
        case title
        case offlinePlaybackLanguages
        case favourite
        case coverUrl
        case id
        case accessLevel
        case playerURLCallback
        case externalAssetID
        case maxHeight
        case thumbnailsPreview
        case longDescription
        case rating
        case episodeInformation
        case categories
        case onlinePlayback
        case vods
        case vodCount
        case paging
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decode(String.self, forKey: .description)
        self.duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        self.title = try container.decode(String.self, forKey: .title)
        self.offlinePlaybackLanguages = try container.decodeIfPresent([String].self, forKey: .offlinePlaybackLanguages)
        self.favourite = try container.decodeIfPresent(Bool.self, forKey: .favourite)
        self.coverUrl = try container.decodeIfPresent(ThumbnailEntry.self, forKey: .coverUrl)
        self.id = try container.decode(Int.self, forKey: .id)
        self.accessLevel = try container.decodeIfPresent(String.self, forKey: .accessLevel)
        self.playerURLCallback = try container.decodeIfPresent(String.self, forKey: .playerURLCallback)
        self.externalAssetID = try container.decodeIfPresent(String.self, forKey: .externalAssetID)
        self.maxHeight = try container.decodeIfPresent(Int.self, forKey: .maxHeight)
        self.thumbnailsPreview = try container.decodeIfPresent(String.self, forKey: .thumbnailsPreview)
        self.longDescription = try container.decodeIfPresent(String.self, forKey: .longDescription) ?? description
        self.rating = try container.decodeIfPresent(Rating.self, forKey: .rating)
        self.episodeInformation = try container.decodeIfPresent(EpisodeInformation.self, forKey: .episodeInformation)
        self.categories = try container.decodeIfPresent([String].self, forKey: .categories)
        self.onlinePlayback = try container.decodeIfPresent(String.self, forKey: .onlinePlayback)
        self.episodes = try container.decodeIfPresent([Episode].self, forKey: .vods)
        self.episodesCount = try container.decodeIfPresent(Int.self, forKey: .vodCount) ?? 1
        self.paging = try container.decodeIfPresent(Paging.self, forKey: .paging)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.description, forKey: .description)
        try container.encodeIfPresent(self.duration, forKey: .duration)
        try container.encode(self.title, forKey: .title)
        try container.encodeIfPresent(self.offlinePlaybackLanguages, forKey: .offlinePlaybackLanguages)
        try container.encodeIfPresent(self.favourite, forKey: .favourite)
        try container.encodeIfPresent(self.coverUrl, forKey: .coverUrl)
        try container.encode(self.id, forKey: .id)
        try container.encodeIfPresent(self.accessLevel, forKey: .accessLevel)
        try container.encodeIfPresent(self.playerURLCallback, forKey: .playerURLCallback)
        try container.encodeIfPresent(self.externalAssetID, forKey: .externalAssetID)
        try container.encodeIfPresent(self.maxHeight, forKey: .maxHeight)
        try container.encodeIfPresent(self.thumbnailsPreview, forKey: .thumbnailsPreview)
        try container.encodeIfPresent(self.longDescription, forKey: .longDescription)
        try container.encodeIfPresent(self.rating, forKey: .rating)
        try container.encodeIfPresent(self.episodeInformation, forKey: .episodeInformation)
        try container.encodeIfPresent(self.categories, forKey: .categories)
        try container.encodeIfPresent(self.onlinePlayback, forKey: .onlinePlayback)
        try container.encodeIfPresent(self.episodes, forKey: .vods)
        try container.encode(self.episodesCount, forKey: .vodCount)
        try container.encodeIfPresent(self.paging, forKey: .paging)
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        return lhs.id == rhs.id && lhs.episodes == rhs.episodes
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(episodes)
    }
    
    func saveThumbnails() async {
        self.coverUrl = await coverUrl?.save()
        for episode in episodes ?? [] {
            await episode.saveThumbnails()
        }
    }
}
