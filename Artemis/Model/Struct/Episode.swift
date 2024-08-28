//
//  Episode.swift
//   Artemis
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation
import SwiftUI

@Observable
class Episode: Codable, Equatable, Hashable, Identifiable, Descriptable, Savable  {
    let description: String
    let duration: Int
    let title: String
    let offlinePlaybackLanguages: [String]?
    let favourite: Bool
    var thumbnailUrl: ThumbnailEntry
    let id: Int
    let type: String?
    let accessLevel: String?
    let playerUrlCallback: String?
    var posterURL: ThumbnailEntry?
    let externalAssetID: String?
    let maxHeight: Int?
    let thumbnailsPreview: String?
    let longDescription: String
    let rating: Rating?
    var episodeInformation: EpisodeInformation?
    let categories: [String]?
    let onlinePlayback: String
    var posterUrl: ThumbnailEntry?
    var watchedAt: Int64?
    var watchProgress: Int?
    var isSaved: Bool
    
    var coverUrl: ThumbnailEntry? {
        return thumbnailUrl
    }
    
    var isValid: Bool {
        return description != "This episode is not available yet."
    }
    
    var parentTitle: String {
        return episodeInformation?.season?.parentTitle ?? title
    }
    
    var parentId: Int {
        return episodeInformation?.season?.parentId ?? id
    }
    
    enum CodingKeys: CodingKey {
        case description
        case duration
        case title
        case offlinePlaybackLanguages
        case favourite
        case thumbnailUrl
        case thumbnailURL
        case id
        case type
        case accessLevel
        case playerURLCallback
        case playerUrlCallback
        case posterURL
        case externalAssetID
        case maxHeight
        case thumbnailsPreview
        case longDescription
        case rating
        case episodeInformation
        case categories
        case onlinePlayback
        case posterUrl
        case watchedAt
        case watchProgress
        case downloaded
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decode(String.self, forKey: .description)
        self.duration = try container.decode(Int.self, forKey: .duration)
        self.title = try container.decode(String.self, forKey: .title).replacing(".00 - ", with: " - ", maxReplacements: 1)
        self.offlinePlaybackLanguages = try container.decodeIfPresent([String].self, forKey: .offlinePlaybackLanguages)
        self.favourite = try container.decode(Bool.self, forKey: .favourite)
        self.thumbnailUrl = try container.decodeIfPresent(ThumbnailEntry.self, forKey: .thumbnailUrl) ?? container.decode(ThumbnailEntry.self, forKey: .thumbnailURL)
        self.id = try container.decode(Int.self, forKey: .id)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.accessLevel = try container.decodeIfPresent(String.self, forKey: .accessLevel)
        self.playerUrlCallback = try container.decodeIfPresent(String.self, forKey: .playerUrlCallback) ?? container.decodeIfPresent(String.self, forKey: .playerURLCallback)
        self.posterURL = try container.decodeIfPresent(ThumbnailEntry.self, forKey: .posterURL)
        self.externalAssetID = try container.decodeIfPresent(String.self, forKey: .externalAssetID)
        self.maxHeight = try container.decodeIfPresent(Int.self, forKey: .maxHeight)
        self.thumbnailsPreview = try container.decodeIfPresent(String.self, forKey: .thumbnailsPreview)
        self.longDescription = try container.decodeIfPresent(String.self, forKey: .longDescription) ?? description
        self.rating = try container.decodeIfPresent(Rating.self, forKey: .rating)
        self.episodeInformation = try container.decodeIfPresent(EpisodeInformation.self, forKey: .episodeInformation)
        self.categories = try container.decodeIfPresent([String].self, forKey: .categories)
        self.onlinePlayback = try container.decode(String.self, forKey: .onlinePlayback)
        self.posterUrl = try container.decodeIfPresent(ThumbnailEntry.self, forKey: .posterUrl)
        self.watchedAt = try container.decodeIfPresent(Int64.self, forKey: .watchedAt)
        self.watchProgress = try container.decodeIfPresent(Int.self, forKey: .watchProgress)
        self.isSaved = OfflineResourceSaver.getResource(id: id) != nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.description, forKey: .description)
        try container.encodeIfPresent(self.duration, forKey: .duration)
        try container.encode(self.title, forKey: .title)
        try container.encodeIfPresent(self.offlinePlaybackLanguages, forKey: .offlinePlaybackLanguages)
        try container.encode(self.favourite, forKey: .favourite)
        try container.encode(self.thumbnailUrl, forKey: .thumbnailUrl)
        try container.encode(self.id, forKey: .id)
        try container.encodeIfPresent(self.type, forKey: .type)
        try container.encodeIfPresent(self.accessLevel, forKey: .accessLevel)
        try container.encodeIfPresent(self.playerUrlCallback, forKey: .playerUrlCallback)
        try container.encodeIfPresent(self.externalAssetID, forKey: .externalAssetID)
        try container.encodeIfPresent(self.maxHeight, forKey: .maxHeight)
        try container.encodeIfPresent(self.thumbnailsPreview, forKey: .thumbnailsPreview)
        try container.encodeIfPresent(self.longDescription, forKey: .longDescription)
        try container.encodeIfPresent(self.rating, forKey: .rating)
        try container.encodeIfPresent(self.episodeInformation, forKey: .episodeInformation)
        try container.encodeIfPresent(self.categories, forKey: .categories)
        try container.encode(self.onlinePlayback, forKey: .onlinePlayback)
        try container.encodeIfPresent(self.posterUrl ?? self.posterURL, forKey: .posterUrl)
        try container.encodeIfPresent(self.watchedAt, forKey: .watchedAt)
        try container.encodeIfPresent(self.watchProgress, forKey: .watchProgress)
        try container.encode(self.isSaved, forKey: .downloaded)
    }
    
    static func == (lhs: Episode, rhs: Episode) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func saveThumbnails() async {
        self.thumbnailUrl = await thumbnailUrl.save()
        self.posterUrl = await posterUrl?.save()
    }
}

struct EpisodeInformation: Codable, Equatable, Hashable {
    let seasonNumber: Int
    let episodeNumber: Int
    let seasonId: Int
    var season: Season?
    
    enum CodingKeys: CodingKey {
        case seasonNumber
        case episodeNumber
        case season
        case seasonData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.seasonNumber = try container.decode(Int.self, forKey: .seasonNumber)
        self.episodeNumber = try container.decode(Int.self, forKey: .episodeNumber)
        self.seasonId = try container.decode(Int.self, forKey: .season)
        self.season = try container.decodeIfPresent(Season.self, forKey: .seasonData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.seasonNumber, forKey: .seasonNumber)
        try container.encode(self.episodeNumber, forKey: .episodeNumber)
        try container.encode(self.seasonId, forKey: .season)
    }
}

struct Rating : Codable, Equatable, Hashable {
    let rating: String?
    let descriptions: [String]?
}
