//
//  Playlist.swift
//  Hidive
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

struct Playlist: Decodable, Equatable, Hashable, Identifiable {
    let description: String
    let duration: Int?
    let title: String
    let offlinePlaybackLanguages: [String]?
    let contentDownload: ContentDownload?
    let favourite: Bool?
    let coverUrl: String
    let id: Int
    let type, accessLevel: String?
    let playerURLCallback: String?
    let posterURL: String?
    let externalAssetID: String?
    let maxHeight: Int?
    let thumbnailsPreview: String?
    let longDescription: String?
    let rating: ContentRating?
    let episodeInformation: EpisodeInformation?
    let categories: [String]?
    let onlinePlayback: String?
    let vods: [Episode]
}
