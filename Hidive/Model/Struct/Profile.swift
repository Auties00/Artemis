//
//  Account.swift
//  Hidive
//
//  Created by Alessandro Autiero on 12/07/24.
//

import Foundation

class Profile: Codable, Equatable, Identifiable {
    var profileId: String
    let accountId: String
    var displayName: String
    let avatar: String
    let type: String
    let category: String?
    var preferences: ProfilePreferences
    
    var id: String {
        return profileId
    }
    
    static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.profileId == rhs.profileId
    }
    
    enum CodingKeys: CodingKey {
        case profileId
        case accountId
        case displayName
        case avatar
        case type
        case category
        case preferences
    }
    
    init(accountId: String) {
        self.profileId = "stub"
        self.accountId = accountId
        self.displayName = "User"
        self.avatar = "https://static.diceplatform.com/prod/original/dce.hidive/profile-avatars/HIDIVE_ProfileAvatar_1000x1000_01_Cyan.T5EZA.fC5F3.png"
        self.category = nil
        self.type = "ADULT"
        self.preferences = ProfilePreferences()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.profileId = try container.decode(String.self, forKey: .profileId)
        self.accountId = try container.decode(String.self, forKey: .accountId)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.avatar = try container.decode(String.self, forKey: .avatar)
        self.type = try container.decode(String.self, forKey: .type)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.preferences = try container.decodeIfPresent(ProfilePreferences.self, forKey: .preferences) ?? ProfilePreferences()
    }
}

class ProfilePreferences: Codable {
    static let supportedSubtitlesLanguages = [
        "false",
        "en-US",
        "es-MX",
        "es-ES",
        "pt-PT"
    ]
    static let supportedAudioLanguages = [
        "ja-JP",
        "en-US"
    ]
    
    var audioLanguage: String
    var subtitlesLanguage: String
    var autoAdvance: Bool
    
    enum CodingKeys: CodingKey {
        case audioLanguage
        case subtitlesLanguage
        case autoAdvance
    }
    
    init(audioLanguage: String? = nil, subtitlesLanguage: String? = nil, autoAdvance: Bool? = nil) {
        self.audioLanguage = audioLanguage ?? ProfilePreferences.supportedAudioLanguages[0]
        self.subtitlesLanguage = subtitlesLanguage ?? ProfilePreferences.supportedSubtitlesLanguages[1]
        self.autoAdvance = autoAdvance ?? true
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.audioLanguage = try container.decodeIfPresent(String.self, forKey: .audioLanguage) ?? ProfilePreferences.supportedAudioLanguages[0]
        self.subtitlesLanguage = (try? container.decodeIfPresent(String.self, forKey: .subtitlesLanguage))
                                 ?? (try? container.decodeIfPresent(Bool.self, forKey: .subtitlesLanguage))?.description
                                 ?? ProfilePreferences.supportedSubtitlesLanguages[1]
        self.autoAdvance = try container.decodeIfPresent(Bool.self, forKey: .autoAdvance) ?? true
    }
}

struct Address: Codable, Equatable, Identifiable {
    var countryCode: String?
    var postalCode: String?
    var administrativeLevel1: String?
    let id: Int
    var label: String
    let exid: String
    let addressType: String
}

