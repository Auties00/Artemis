//
//  ScheduleResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 11/08/24.
//

import Foundation

struct ScheduleResponse: Decodable {
    let layout: String
    let elements: [ScheduleElementEntry]
}

enum ScheduleElementEntry: Decodable {
    case unknown
    case groupList(ScheduleElement)
    
    enum CodingKeys: String, CodingKey {
        case type = "$type"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch(try container.decode(String.self, forKey: .type)) {
        case "groupList":
            self = .groupList(try ScheduleElement(from: decoder))
        default:
            self = .unknown
        }
    }
}

struct ScheduleElement: Decodable {
    let attributes: ScheduleElementAttributes
}

struct ScheduleElementAttributes: Decodable {
    let groups: [ScheduleElementGroup]
}

struct ScheduleElementGroup: Decodable {
    let attributes: ScheduleElementGroupAttributes
}

struct ScheduleElementGroupAttributes: Decodable {
    let cards: [ScheduleElementGroupCard]?
    let label: String?
}

struct ScheduleElementGroupCard: Decodable, Identifiable {
    let id: UUID
    let attributes: ScheduleElementGroupCardAttributes
    
    enum CodingKeys: CodingKey {
        case attributes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.attributes = try container.decode(ScheduleElementGroupCardAttributes.self, forKey: .attributes)
    }
}

struct ScheduleElementGroupCardAttributes: Decodable {
    let header: [ScheduleElementGroupCardHeader]
    let content: [ScheduleElementCardContentEntry]
    let groupingData: ScheduleElementGroupCardGroupingData
    let action: ScheduleElementGroupCardAction
}

struct ScheduleElementGroupCardHeader: Decodable {
    let attributes: ScheduleElementGroupCardHeaderAttributes
}

struct ScheduleElementGroupCardHeaderAttributes: Decodable {
    let source: String
    let width: Int
    let height: Int
}

enum ScheduleElementCardContentEntry: Decodable {
    case unknown
    case gridBlock(ScheduleElementGroupCardContent)
    
    enum CodingKeys: String, CodingKey {
        case type = "$type"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch(try container.decode(String.self, forKey: .type)) {
        case "gridBlock":
            self = .gridBlock(try ScheduleElementGroupCardContent(from: decoder))
        default:
            self = .unknown
        }
    }
}

struct ScheduleElementGroupCardContent: Decodable {
    let attributes: ScheduleElementGroupCardContentAttributes
}

struct ScheduleElementGroupCardContentAttributes: Decodable {
    let elements: [ScheduleElementGroupCardElementEntry]
}

enum ScheduleElementGroupCardElementEntry: Decodable {
    case unknown
    case textBlock(ScheduleElementGroupCardTextBlockElement)
    case tag(ScheduleElementGroupCardTagElement)
    case tagList(ScheduleElementGroupCardTagListElement)
    
    enum CodingKeys: String, CodingKey {
        case type = "$type"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch(try container.decode(String.self, forKey: .type)) {
        case "textBlock":
            self = .textBlock(try ScheduleElementGroupCardTextBlockElement(from: decoder))
        case "tag":
            self = .tag(try ScheduleElementGroupCardTagElement(from: decoder))
        case "tagList":
            self = .tagList(try ScheduleElementGroupCardTagListElement(from: decoder))
        default:
            self = .unknown
        }
    }
}

struct ScheduleElementGroupCardTextBlockElement: Decodable {
    let attributes: ScheduleElementGroupCardTextBlockElementAttributes
}

struct ScheduleElementGroupCardTextBlockElementAttributes: Decodable {
    let text: String
    let format: String?
}

struct ScheduleElementGroupCardTagListElement: Decodable {
    let attributes: ScheduleElementGroupCardTagListElementAttributes
}

struct ScheduleElementGroupCardTagListElementAttributes: Decodable {
    let tags: [ScheduleElementGroupCardElementEntry]
}

struct ScheduleElementGroupCardTagElement: Decodable {
    let attributes: ScheduleElementGroupCardTagElementAttributes
}

struct ScheduleElementGroupCardTagElementAttributes: Decodable {
    let text: ScheduleElementGroupCardTextBlockElement
    let icon: ScheduleElementGroupCardIconElement?
}

struct ScheduleElementGroupCardIconElement: Decodable {
    let attributes: ScheduleElementGroupCardIconElementAttributes
}

struct ScheduleElementGroupCardIconElementAttributes: Decodable {
    let icon: String
    let size: Int
}

struct ScheduleElementGroupCardGroupingData: Decodable {
    let scheduledAt: String
    let releaseState: String
    let computedState: String
    let releaseType: String
    let description: String
}

struct ScheduleElementGroupCardAction: Decodable {
    let type: String
    let data: ScheduleElementGroupCardActionData
}

struct ScheduleElementGroupCardActionData: Decodable {
    let type: String
    let title: String
    let id: String
}
