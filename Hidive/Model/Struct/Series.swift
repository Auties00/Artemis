//
//  Series.swift
//  Hidive
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

class Series : Codable, Equatable, Hashable, Identifiable, Descriptable, Savable {
    let id: Int
    let title: String
    let description: String
    let longDescription: String
    var smallCoverUrl: ThumbnailEntry?
    var coverUrl: ThumbnailEntry?
    var seasons: [Season]?
    let rating: Rating?
    let seasonCount: Int?
    
    var parentTitle: String {
        return title
    }
    
    var parentId: Int {
        return id
    }
    
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? container.decode(Int.self, forKey: .seriesId)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.longDescription = try container.decode(String.self, forKey: .longDescription)
        self.smallCoverUrl = try container.decodeIfPresent(ThumbnailEntry.self, forKey: .smallCoverUrl)
        self.coverUrl = try container.decodeIfPresent(ThumbnailEntry.self, forKey: .coverUrl)
        self.seasons = try container.decodeIfPresent([Season].self, forKey: .seasons)
        self.rating = try container.decodeIfPresent(Rating.self, forKey: .rating) ?? container.decodeIfPresent(Rating.self, forKey: .contentRating)
        self.seasonCount = try container.decodeIfPresent(Int.self, forKey: .seasonCount) ?? seasons?.count
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.description, forKey: .description)
        try container.encode(self.longDescription, forKey: .longDescription)
        try container.encodeIfPresent(self.smallCoverUrl, forKey: .smallCoverUrl)
        try container.encodeIfPresent(self.coverUrl, forKey: .coverUrl)
        try container.encodeIfPresent(self.seasons, forKey: .seasons)
        try container.encodeIfPresent(self.rating, forKey: .rating)
        try container.encodeIfPresent(self.seasonCount, forKey: .seasonCount)
    }
    
    static func == (lhs: Series, rhs: Series) -> Bool {
        return lhs.id == rhs.id && rhs.seasons == lhs.seasons
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(seasons)
    }
    
    func saveThumbnails() async {
        self.smallCoverUrl = await smallCoverUrl?.save()
        self.coverUrl = await coverUrl?.save()
    }
}
