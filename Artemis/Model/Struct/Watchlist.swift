//
//  Watchlist.swift
//  Hidive
//
//  Created by Alessandro Autiero on 27/07/24.
//

import Foundation

@Observable
class Watchlists: Equatable {
    var data: [Watchlist]
    var moreDataAvailable: Bool
    var lastSeen: String
    init(response: WatchlistsResponse) {
        self.data = response.watchlists
        self.moreDataAvailable = response.pagingInfo.moreDataAvailable
        self.lastSeen = response.pagingInfo.lastSeen
    }
    
    func update(response: WatchlistsResponse) {
        self.data = response.watchlists
        self.moreDataAvailable = response.pagingInfo.moreDataAvailable
        self.lastSeen = response.pagingInfo.lastSeen
    }
    
    static func == (lhs: Watchlists, rhs: Watchlists) -> Bool {
        return lhs.data == rhs.data && lhs.moreDataAvailable == rhs.moreDataAvailable && lhs.lastSeen == rhs.lastSeen
    }
}

@Observable
class Watchlist: Decodable, Identifiable, Hashable, Equatable, ObservableObject {
    let watchlistExternalId: Int
    let ownerExternalId: String
    var name: String
    var thumbnails: [ThumbnailEntry]
    let shareablePath: String
    let ownership: String
    var content: [DescriptableEntry]?
    let paging: Paging?
    
    var id: Int {
        return watchlistExternalId
    }
    
    var shareLink: URL {
        return URL(string: "https://www.hidive.com/watchlists/\(watchlistExternalId)?owner=\(ownerExternalId)")!
    }
    
    static func == (lhs: Watchlist, rhs: Watchlist) -> Bool {
        return lhs.id == rhs.id && lhs.content == rhs.content
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(content)
    }
    
    enum CodingKeys: CodingKey {
        case watchlistExternalId
        case ownerExternalId
        case name
        case thumbnails
        case shareablePath
        case ownership
        case content
        case pagingInfo
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.watchlistExternalId = try container.decode(Int.self, forKey: .watchlistExternalId)
        self.ownerExternalId = try container.decode(String.self, forKey: .ownerExternalId)
        self.name = try container.decode(String.self, forKey: .name)
        self._thumbnails = try container.decode([ThumbnailEntry].self, forKey: .thumbnails)
        self.shareablePath = try container.decode(String.self, forKey: .shareablePath)
        self.ownership = try container.decode(String.self, forKey: .ownership)
        self._content = try container.decodeIfPresent([DescriptableEntry].self, forKey: .content)
        self.paging = try container.decodeIfPresent(Paging.self, forKey: .pagingInfo)
    }
}
