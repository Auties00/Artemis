//
//  DashboardResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 12/07/24.
//

import Foundation

struct DashboardResponse : Decodable, Equatable {
    var heroes: [Hero]
    var buckets: [Bucket]
    let paging: Paging?
    
    static func == (lhs: DashboardResponse, rhs: DashboardResponse) -> Bool {
        return lhs.heroes == rhs.heroes && lhs.buckets == rhs.buckets
    }
    
    var continueWatchingBucket: Bucket? {
        return buckets.first(where: {
            $0.name?.caseInsensitiveCompare("Continue Watching") == .orderedSame
        })
    }
}

@Observable
class Hero : Decodable, Identifiable, Equatable {
    let heroId: Int
    let title: String?
    let description: String?
    let titleImage: String?
    let enabled: Bool?
    let ctaText: String?
    let link: HeroLink
    let imageUrl: String?
    var lastWatchedEpisode: Episode?
    
    var id: Int {
        return heroId
    }
    
    static func == (lhs: Hero, rhs: Hero) -> Bool {
        return lhs.id == rhs.id && lhs.link == rhs.link
    }
    
    enum CodingKeys: CodingKey {
        case heroId
        case title
        case description
        case titleImage
        case enabled
        case ctaText
        case link
        case imageUrl
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.heroId = try container.decode(Int.self, forKey: .heroId)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.titleImage = try container.decodeIfPresent(String.self, forKey: .titleImage)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        self.ctaText = try container.decodeIfPresent(String.self, forKey: .ctaText)
        self.link = try container.decode(HeroLink.self, forKey: .link)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
    }
}

class HeroLink : Decodable, Equatable {
    let type: String?
    var event: DescriptableEntry
    
    static func == (lhs: HeroLink, rhs: HeroLink) -> Bool {
        return lhs.type == rhs.type && lhs.event == rhs.event
    }
}

@Observable // Needed for Continue Watching updates, special condition
class Bucket : Decodable, Identifiable, Equatable {
    var id: UUID
    let type: String?
    let name: String?
    let exid: String?
    let paging: Paging?
    var contentList: [DescriptableEntry]
    
    enum CodingKeys: CodingKey {
        case type
        case name
        case exid
        case paging
        case contentList
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.exid = try container.decodeIfPresent(String.self, forKey: .exid)
        self.paging = try container.decodeIfPresent(Paging.self, forKey: .paging)
        self.contentList = try container.decode([DescriptableEntry].self, forKey: .contentList)
    }
    
    static func == (lhs: Bucket, rhs: Bucket) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.contentList == rhs.contentList
    }
}
