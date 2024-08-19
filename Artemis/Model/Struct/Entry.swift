//
//  Entry.swift
//   Artemis
//
//  Created by Alessandro Autiero on 28/07/24.
//

import Foundation

enum DescriptableEntry: Codable, Hashable, Identifiable, Descriptable {
    case series(Series)
    case season(Season)
    case episode(Episode)
    case playlist(Playlist)
    
    enum CodingKeys: CodingKey {
        case type
    }
    
    var id: Int {
        return wrappedValue.id
    }
    
    var parentId: Int {
        return wrappedValue.parentId
    }
    
    var title: String {
        return wrappedValue.title
    }
    
    var description: String {
        return wrappedValue.description
    }
    
    var longDescription: String {
        return wrappedValue.longDescription
    }
    
    var coverUrl: ThumbnailEntry? {
        return wrappedValue.coverUrl
    }
    
    var parentTitle: String {
        return wrappedValue.parentTitle
    }
    
    var type: String {
        switch(self) {
        case .series:
            return "VOD_SERIES"
        case .season:
            return "VOD_SEASON"
        case .episode:
            return "VOD"
        case .playlist:
            return "PLAYLIST"
        }
    }
    
    var wrappedValue: Descriptable {
        switch(self) {
        case .series(series: let series):
            return series
        case .season(season: let season):
            return season
        case .episode(series: let episode):
            return episode
        case .playlist(playlist: let playlist):
            return playlist
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type)
        switch(type) {
        case "VOD_SEASON":
            self = .season(try Season(from: decoder))
        case "VOD_SERIES":
            self = .series(try Series(from: decoder))
        case "VOD":
            self = .episode(try Episode(from: decoder))
        case "PLAYLIST":
            self = .playlist(try Playlist(from: decoder))
        default:
            fatalError("Unknown bucket type: \(type ?? "unknown")")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        switch(self) {
        case .season(let season):
            try season.encode(to: encoder)
        case .series(let series):
            try series.encode(to: encoder)
        case .episode(let episode):
            try episode.encode(to: encoder)
        case .playlist(let playlist):
            try playlist.encode(to: encoder)
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


enum EpisodableEntry: Codable, Hashable, Identifiable {
    case season(Season)
    case playlist(Playlist)
    
    enum CodingKeys: CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type)
        switch(type) {
        case "VOD_SEASON":
            self = .season(try Season(from: decoder))
        case "PLAYLIST":
            self = .playlist(try Playlist(from: decoder))
        default:
            fatalError("Unknown bucket type: \(type ?? "unknown")")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        switch(self) {
        case .season(let season):
            try season.encode(to: encoder)
        case .playlist(let playlist):
            try playlist.encode(to: encoder)
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
    }
    
    var id: Int {
        switch(self) {
        case .season(season: let season):
            return season.id
        case .playlist(playlist: let playlist):
            return playlist.id
        }
    }

    var type: String {
        switch(self) {
        case .season:
            return "VOD_SEASON"
        case .playlist:
            return "PLAYLIST"
        }
    }
    
    var wrappedValue: any Episodable {
        switch(self) {
        case .season(season: let season):
            return season
        case .playlist(playlist: let playlist):
            return playlist
        }
    }
    
    var descriptableEntry: DescriptableEntry {
        switch(self) {
        case .season(season: let season):
            return .season(season)
        case .playlist(playlist: let playlist):
            return .playlist(playlist)
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum DownloadableEntry: Identifiable, Hashable {
    case season(Season)
    case playlist(Playlist)
    case episode(Episode)
    
    var id: Int {
        switch(self) {
        case .season(let season):
            return season.id
        case .playlist(let playlist):
            return playlist.id
        case .episode(let episode):
            return episode.id
        }
    }
    
    var parentId: Int {
        switch(self) {
        case .season(let season):
            return season.parentId
        case .playlist(let playlist):
            return playlist.parentId
        case .episode(let episode):
            return episode.parentId
        }
    }
    
    var isSaved: Bool {
        switch(self) {
        case .season(let season):
            return season.isSaved
        case .playlist(let playlist):
            return playlist.isSaved
        case .episode(let episode):
            return episode.isSaved
        }
    }

    var descriptableEntry: DescriptableEntry {
        switch(self) {
        case .season(let season):
            return .season(season)
        case .playlist(let playlist):
            return .playlist(playlist)
        case .episode(let episode):
            return .episode(episode)
        }
    }
}

enum DownloadedEntry: Identifiable, Codable, Hashable {
    case series(Series)
    case playlist(Playlist)
    
    var id: Int {
        switch(self) {
        case .series(let series):
            return series.id
        case .playlist(let playlist):
            return playlist.id
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var type: String {
        switch(self) {
        case .series:
            return "VOD_SERIES"
        case .playlist:
            return "PLAYLIST"
        }
    }
    
    var savedEpisodesCount: Int {
        switch(self) {
        case .series(let series):
            return series.seasons?.map {
                $0.episodes?.filter { $0.isSaved }.count ?? 0
            }.reduce(0) { $0 + $1 } ?? 0
        case .playlist(let playlist):
            return playlist.episodes?.filter { $0.isSaved }.count ?? 0
        }
    }
    
    
    var wrappedValue: Descriptable {
        switch(self) {
        case .series(season: let series):
            return series
        case .playlist(playlist: let playlist):
            return playlist
        }
    }
    
    enum CodingKeys: CodingKey {
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type)
        switch(type) {
        case "VOD_SERIES":
            self = .series(try Series(from: decoder))
        case "PLAYLIST":
            self = .playlist(try Playlist(from: decoder))
        default:
            fatalError("Unknown bucket type: \(type ?? "unknown")")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        switch(self) {
        case .series(let series):
            try series.encode(to: encoder)
        case .playlist(let playlist):
            try playlist.encode(to: encoder)
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
    }
}

enum ThumbnailEntry: Codable {
    case url(String)
    case data(Data)
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            self = .url(try container.decode(String.self))
        }catch {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self = .data(try container.decode(Data.self, forKey: .data))
        }
    }
    
    enum CodingKeys: CodingKey {
        case data
    }
    
    func encode(to encoder: Encoder) throws {
        switch(self) {
        case .data(let data):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(data, forKey: .data)
        case .url(let url):
            var container = encoder.singleValueContainer()
            try container.encode(url)
        }
    }
    
    func save() async -> ThumbnailEntry {
        switch(self) {
        case .data:
            return self
        case .url(let url):
            guard let data = try? await ImageCache.shared.getImageData(url: url) else {
                return self
            }
            
            return .data(data)
        }
    }
}
