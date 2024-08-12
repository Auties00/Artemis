//
//  CategoriesResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 04/08/24.
//

import Foundation

struct CategoriesResponse: Decodable {
    let buckets: [CategoryBucket]
    let paging: Paging
}

struct CategoryBucket: Decodable {
    let type: String
    let name: String
    let paging: Paging
    let contentList: [CategoryEntry]
}

enum CategoryEntry: Decodable {
    case unknown
    case sectionLink(CategorySectionLink)
    
    enum CodingKeys: CodingKey {
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type)
        self = switch(type) {
        case "SECTION_LINK":
            .sectionLink(try CategorySectionLink(from: decoder))
        default:
            .unknown
        }
    }
}

class CategorySectionLink: Decodable, Identifiable {
    let type: String
    let accessLevel: String
    let id: Int
    let sectionId: Int
    let sectionName: String
    let title: String
    let description: String
    let thumbnailUrl: String
    let videoUrl: String
}
