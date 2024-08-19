//
//  PlaybackResponse.swift
//   Artemis
//
//  Created by Alessandro Autiero on 18/07/24.
//

import Foundation

struct Playback: Decodable {
    let dash: [PlaybackEntry]
    let hls: [PlaybackEntry]
    
    enum CodingKeys: CodingKey {
        case dash
        case hls
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let dash = try? container.decodeIfPresent([PlaybackEntry].self, forKey: .dash) {
            self.dash = dash
        }else if let dash = try? container.decodeIfPresent(PlaybackEntry.self, forKey: .dash) {
            self.dash = [dash]
        }else {
            self.dash = []
        }
        
        if let hls = try? container.decodeIfPresent([PlaybackEntry].self, forKey: .hls) {
            self.hls = hls
        }else if let hls = try? container.decodeIfPresent(PlaybackEntry.self, forKey: .hls) {
            self.hls = [hls]
        }else {
            self.hls = []
        }
    }
}

struct PlaybackEntry: Decodable  {
    let subtitles: [Subtitle]
    let url: String
    let drm: DRM
    var m3u8Playlist: String?
    
    enum CodingKeys: CodingKey {
        case subtitles
        case url
        case drm
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.subtitles = try container.decode([Subtitle].self, forKey: .subtitles)
        self.url = try container.decode(String.self, forKey: .url)
        self.drm = try container.decode(DRM.self, forKey: .drm)
    }
}

struct DRM: Decodable  {
    let encryptionMode: String
    let containerType: String
    let jwtToken: String
    let url: String
    let keySystems: [String]
}

struct Subtitle: Decodable  {
    let format, language: String
    let url: String
}
