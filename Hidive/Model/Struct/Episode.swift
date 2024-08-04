//
//  Episode.swift
//  Hidive
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

struct Episode: Decodable, Equatable, Hashable, Identifiable {
    let accessLevel: String?
    let availablePurchases: [String]?
    let licenceIds: [String]?
    let id: Int
    let title: String
    let description: String
    let thumbnailUrl: String
    let posterUrl: String?
    let duration: Int?
    let favourite: Bool?
    let contentDownload: EpisodeDownload?
    let offlinePlaybackLanguages: [String]?
    let externalAssetId: String?
    let thumbnailsPreview: String?
}

struct EpisodeDownload : Decodable, Equatable, Hashable {
    let permission: String
}

