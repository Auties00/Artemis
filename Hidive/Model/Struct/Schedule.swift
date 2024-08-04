//
//  Schedule.swift
//  Hidive
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

fileprivate let dateFormatter = ISO8601DateFormatter()

struct ScheduleEntry: Decodable, Equatable, Hashable {
    let title: String
    let route: String
    let delayedFrom: String
    let delayedUntil: String
    let status: String
    let episodeDate: Date
    let episodeNumber: Int
    let episodes: Int
    let lengthMin: Int
    let donghua: Bool
    let airType: String
    let mediaTypes: [MediaType]
    let imageVersionRoute: String
    let streams: [String:String]
    let airingStatus: String
    
    enum CodingKeys: CodingKey {
        case title
        case route
        case delayedFrom
        case delayedUntil
        case status
        case episodeDate
        case episodeNumber
        case episodes
        case lengthMin
        case donghua
        case airType
        case mediaTypes
        case imageVersionRoute
        case streams
        case airingStatus
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.route = try container.decode(String.self, forKey: .route)
        self.delayedFrom = try container.decode(String.self, forKey: .delayedFrom)
        self.delayedUntil = try container.decode(String.self, forKey: .delayedUntil)
        self.status = try container.decode(String.self, forKey: .status)
        let episodeDateString = try container.decode(String.self, forKey: .episodeDate)
        self.episodeDate = dateFormatter.date(from: episodeDateString)!
        self.episodeNumber = try container.decode(Int.self, forKey: .episodeNumber)
        self.episodes = try container.decodeIfPresent(Int.self, forKey: .episodes) ?? -1
        self.lengthMin = try container.decodeIfPresent(Int.self, forKey: .lengthMin) ?? -1
        self.donghua = try container.decode(Bool.self, forKey: .donghua)
        self.airType = try container.decode(String.self, forKey: .airType)
        self.mediaTypes = try container.decode([MediaType].self, forKey: .mediaTypes)
        let route = try container.decode(String.self, forKey: .imageVersionRoute)
        self.imageVersionRoute = "https://img.animeschedule.net/production/assets/public/img/\(route)"
        self.streams = try container.decode([String:String].self, forKey: .streams)
        self.airingStatus = try container.decode(String.self, forKey: .airingStatus)
    }
}

struct MediaType: Decodable, Equatable, Hashable {
    let name: String
    let route: String
}
