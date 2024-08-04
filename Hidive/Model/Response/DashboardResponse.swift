//
//  DashboardResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 12/07/24.
//

import Foundation

struct DashboardResponse : Decodable {
    let heroes: [Hero]
    let buckets: [Bucket]
    let paging: BucketPaging
}

struct Hero : Decodable, Identifiable {
    let heroId: Int
    let title: String?
    let description: String?
    let titleImage: String?
    let enabled: Bool?
    let ctaText: String?
    let link: HeroLink?
    let imageUrl: String?
    
    var id: Int {
        return heroId
    }
}

struct HeroLink : Decodable, Equatable {
    let type: String?
    let event: BucketEntry?
}

struct ContentRating : Decodable, Equatable, Hashable {
    let rating: String?
    let descriptions: [String]?
}

struct Bucket : Decodable, Identifiable, Equatable {
    let id: UUID
    let type: String?
    let rowTypeData: BucketData?
    let name: String?
    let exid: String?
    let paging: BucketPaging?
    let contentList: [BucketEntry]?
    
    enum CodingKeys: CodingKey {
        case type
        case rowTypeData
        case name
        case exid
        case paging
        case contentList
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.rowTypeData = try container.decodeIfPresent(BucketData.self, forKey: .rowTypeData)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.exid = try container.decodeIfPresent(String.self, forKey: .exid)
        self.paging = try container.decodeIfPresent(BucketPaging.self, forKey: .paging)
        self.contentList = try container.decodeIfPresent([BucketEntry].self, forKey: .contentList)
    }
}

struct BucketData : Decodable, Equatable {
    let title: String?
    let rowCount: Int?
    let rowType: String?
    let playlistImageType: String?
    let hideMetadata: Bool?
}

struct BucketPaging : Decodable, Equatable {
    let moreDataAvailable: Bool?
    let lastSeen: String?
}

enum BucketEntry: Decodable, Hashable, Identifiable {
    case series(Series)
    case season(Season)
    case episode(Episode)
    case playlist(Playlist)
    
    enum CodingKeys: CodingKey {
        case type
    }
    
    var id: Int? {
        switch(self) {
        case .series(series: let series):
            return series.id
        case .season(season: let season):
            return season.id
        case .episode(series: let episode):
            return episode.id
        case .playlist(playlist: let playlist):
            return playlist.id
        }
    }
    
    var title: String? {
        switch(self) {
        case .series(series: let series):
            return series.title
        case .season(season: let season):
            return season.series?.title ?? season.title
        case .episode(series: let episode):
            return episode.title
        case .playlist(playlist: let playlist):
            return playlist.title
        }
    }
    
    var description: String? {
        switch(self) {
        case .series(series: let series):
            return series.description
        case .season(season: let season):
            return season.series?.description ?? season.description
        case .episode(series: let episode):
            return episode.description
        case .playlist(playlist: let playlist):
            return playlist.description
        }
    }
    
    var longDescription: String? {
        switch(self) {
        case .series(series: let series):
            return series.longDescription
        case .season(season: let season):
            return season.longDescription
        case .episode(series: let episode):
            return episode.description
        case .playlist(playlist: let playlist):
            return playlist.longDescription
        }
    }
    
    var coverUrl: String? {
        switch(self) {
        case .series(series: let series):
            return series.coverUrl
        case .season(season: let season):
            return season.coverUrl
        case .episode(series: let episode):
            return episode.thumbnailUrl
        case .playlist(playlist: let playlist):
            return playlist.coverUrl
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
