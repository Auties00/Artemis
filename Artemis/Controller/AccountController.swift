//
//  AccountController.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import Foundation
import SwiftUI

@Observable
class AccountController {
    static let offlineAudioLanguageKey: String = "audioLanguage"
    static let offlineSubtitlesLanguageKey: String = "subtitlesLanguage"
    static let offlineAutoAdvanceKey: String = "autoAdvance"
    
    var profile: AsyncResult<Profile?> = .empty
    var dashboard: AsyncResult<DashboardResponse> = .empty
    
    private let apiController: ApiController
    private let animeController: AnimeController
    init(apiController: ApiController, animeController: AnimeController) {
        self.apiController = apiController
        self.animeController = animeController
    }
    
    func login() async {
        if(apiController.loggedIn) {
            await apiController.onLoggedIn()
            let profileId = UserDefaults.standard.string(forKey: "profileId")
            await initializeProfile(profileId: profileId)
        }else {
            await loginGuest()
        }
    }
    
    private func loginGuest() async {
        do {
            self.profile = .loading
            let loginResponse: LoginResponse? = try? await apiController.sendRequest(
                method: "POST",
                path: "v2/login/guest/checkin",
                requiresLogin: false
            )
            try await handleLoginResponse(loginResponse: loginResponse, loggedIn: false)
            self.profile = .success(nil)
            await apiController.onLoggedIn()
        }catch let error {
            self.profile = .error(error)
            await apiController.onLoggedIn()
        }
    }
    
    func loginUser(email: String, password: String) async -> Bool {
        self.profile = .loading
        do {
            let request = LoginRequest(id: email, secret: password)
            let loginResponse: LoginResponse? = try? await apiController.sendRequest(
                method: "POST",
                path: "v2/login",
                data: request
            )
            try await handleLoginResponse(loginResponse: loginResponse, loggedIn: true)
            await initializeProfile(profileId: nil)
            await loadDashboard()
            return true
        }catch let error {
            self.profile = .error(error)
            return false
        }
    }
    
    func register(email: String, password: String, tracking: Bool) async -> Bool {
        do {
            let request = RegisterRequest(
                email: email,
                secret: password,
                consentAnswers: [
                    ConsentAnswer(
                        answer: tracking,
                        promptField: "consentFormCheckbox2"
                    ),
                    ConsentAnswer(
                        answer: true, // tos
                        promptField: "consentFormCheckbox1"
                    )
                ]
            )
            let response: RegistrationResponse = try await apiController.sendRequest(
                method: "POST",
                path: "v2/user",
                data: request
            )
            if let status = response.status, status != 200 {
                self.profile = .error(RegisterError.invalidCode(code: response.code ?? "UNKNOWN"))
                return false
            }
            
            let authorisationToken = response.authorisationToken
            let refreshToken = response.refreshToken
            apiController.authorisationToken = authorisationToken
            apiController.refreshToken = refreshToken
            let loggedIn = authorisationToken != nil && refreshToken != nil
            apiController.loggedIn = loggedIn
            if(loggedIn) {
                await initializeProfile(profileId: nil)
                await loadDashboard()
            }
            
            return true
        }catch let error {
            self.profile = .error(error)
            return false
        }
    }
    
    private func handleLoginResponse(loginResponse: LoginResponse?, loggedIn: Bool) async throws {
        guard let loginResponse = loginResponse else {
            throw LoginError.invalidCredentials
        }
        
        guard let authorisationToken = loginResponse.authorisationToken else {
            throw LoginError.missingData(name: "authorisationToken")
        }
        
        guard let refreshToken = loginResponse.refreshToken else {
            throw LoginError.missingData(name: "refreshToken")
        }
        
        apiController.authorisationToken = authorisationToken
        apiController.refreshToken = refreshToken
        apiController.loggedIn = loggedIn
    }
    
    func resetPassword(email: String) async throws {
        let request = ResetPasswordRequest(id: email, provider: "ID")
        let _ = try await apiController.sendRequest(
            method: "POST",
            path: "v2/reset-password/create",
            data: request
        )
    }
    
    func loadDashboard(bucketsCount: Int = 10, entriesPerBucketCount: Int = 25) async {
        do {
            let isRefresh = dashboard.value != nil
            let startTime = Date.now.millisecondsSince1970
            
            if(isRefresh) {
                self.dashboard = .loading
            }
            
            var result: DashboardResponse = try await apiController.sendRequest(
                method: "GET",
                path: "v4/content/home?bpp=\(bucketsCount)&rpp=\(entriesPerBucketCount)&displaySectionLinkBuckets=SHOW&displayEpgBuckets=HIDE&displayEmptyBucketShortcuts=SHOW&displayContentAvailableOnSignIn=SHOW&displayGeoblocked=HIDE&bspp=\(bucketsCount)"
            )
            
            // Cache the episodes that don't have metadata asyncronoyusly
            let cachedEpisodes = try await withThrowingTaskGroup(of: Episode.self) { group in
                for bucket in result.buckets {
                    for bucketEntry in bucket.contentList {
                        if case .episode(let episode) = bucketEntry {
                            if episode.episodeInformation == nil {
                                group.addTask {
                                    try await self.animeController.getEpisode(id: episode.id, includePlayback: false)
                                }
                            }
                        }
                    }
                }
                
                var results: [Int:Episode] = [:]
                while let result = try await group.next() {
                    results[result.id] = result
                }
                return results
            }
            
            // Syncronously insert the episodes' metadata
            for bucket in result.buckets {
                var attributedEntries: [DescriptableEntry] = []
                for bucketEntry in bucket.contentList {
                    if case .episode(let episode) = bucketEntry {
                        if let cachedEpisode = cachedEpisodes[episode.id] {
                            attributedEntries.append(.episode(cachedEpisode))
                        }
                    }else {
                        attributedEntries.append(bucketEntry)
                    }
                }
                bucket.contentList = attributedEntries
            }
            
            // Syncronously remove duplicates from Continue Watching (can't do it before to save time because we don't have the data)
            var continueWatchingSeriesDict: [Int:Episode] = [:]
            if let continueWatchingBucket = result.continueWatchingBucket {
                var uniqueContent: [DescriptableEntry] = []
                var seriesIds: Set<Int> = Set()
                for buckeEntry in continueWatchingBucket.contentList {
                    if case .episode(let episode) = buckeEntry {
                        let seriesId = episode.parentId
                        let (added, _) = seriesIds.insert(seriesId)
                        if(added) {
                            uniqueContent.append(buckeEntry)
                            continueWatchingSeriesDict[seriesId] = episode
                        }
                    }
                }
                continueWatchingBucket.contentList = uniqueContent
            }
            
            // Cache the last watched episode for each hero asyncronoyusly
            // Prefer data coming from the "Continue Watching" bucket over finding the last episode manually
            let knownSeriesLastEpisodes = continueWatchingSeriesDict
            let attributedHeroes: [Hero] = try await withThrowingTaskGroup(of: (hero: Hero, episodable: DescriptableEntry?, episode: Episode?).self) { group in
                for hero in result.heroes {
                    group.addTask {
                        switch(hero.link.event) {
                        case .season(let unattributedSeason):
                            let series = try await self.animeController.getSeries(id: unattributedSeason.parentId)
                            let lastWatchedEpisode = try await self.getLastWatchedEpisode(series: series, known: knownSeriesLastEpisodes)
                            return (hero, .series(series), lastWatchedEpisode)
                        case .series(let unattributedSeries):
                            let series = try await self.animeController.getSeries(id: unattributedSeries.id)
                            let lastWatchedEpisode = try await self.getLastWatchedEpisode(series: series, known: knownSeriesLastEpisodes)
                            return (hero, .series(series), lastWatchedEpisode)
                        case .playlist(let unattributedPlaylist):
                            let playlist = try await self.animeController.getPlaylist(id: unattributedPlaylist.id)
                            let lastWatchedEpisode = self.getLastWatchedEpisode(episodable: playlist, known: knownSeriesLastEpisodes)
                            return (hero, .playlist(playlist), lastWatchedEpisode)
                        case .episode:
                            return (hero, nil, nil)
                        }
                    }
                }
                
                var results: [Hero] = []
                while let (hero, data, lastWatchedEpisode) = try await group.next() {
                    if let descriptableEntry = data {
                        hero.link.event = descriptableEntry
                        hero.lastWatchedEpisode = lastWatchedEpisode
                        results.append(hero)
                    }
                }
                return results
            }
            
            // Synchronously insert the last watched episode into each hero
            result.heroes = attributedHeroes
            
            if(isRefresh) {
                let sleepTime = 750 - (Date.now.millisecondsSince1970 - startTime)
                if sleepTime > 0 {
                    try? await Task.sleep(for: .milliseconds(sleepTime))
                }
            }
            
            self.dashboard = .success(result)
        }catch let error {
            self.dashboard = .error(error)
        }
    }
    
    private func getLastWatchedEpisode(series: Series, known: [Int:Episode]) async throws -> Episode? {
        if let cached = known[series.id] {
            return cached
        }
        
        var lastWatchedEpisode: Episode? = nil
        for season in series.seasons ?? [] {
            let season = try await self.animeController.getSeason(id: season.id)
            if let seasonLastWatchedEpisode = getLastWatchedEpisode(episodable: season) {
                lastWatchedEpisode = seasonLastWatchedEpisode
            }
        }
        return lastWatchedEpisode
    }
    
    private func getLastWatchedEpisode(episodable: Episodable, known: [Int:Episode]? = nil) -> Episode? {
        if let cached = known?[episodable.id] {
            return cached
        }
        
        var lastWatchedEpisode: Episode? = nil
        for episode in episodable.episodes ?? [] {
            if episode.watchProgress != nil {
                lastWatchedEpisode = episode
            }
        }
        return lastWatchedEpisode
    }
    
    func isLoggedIn() -> Bool {
        return apiController.loggedIn
    }
    
    func logout() async {
        apiController.authorisationToken = nil
        apiController.refreshToken = nil
        apiController.loggedIn = false
        await self.loginGuest()
    }
    
    private func initializeProfile(profileId: String?) async {
        do {
            self.profile = .loading
            let selectedProfile = try await getSelectedProfile(profileId: profileId)
            persistProfilePreferences(profile: selectedProfile)
            self.profile = .success(selectedProfile)
        }catch let error {
            self.profile = .error(error)
        }
    }
    
    func activateProfile(profileId: String? = nil) async {
        do {
            self.profile = .loading
            let profileId = if let profileId = profileId {
                profileId
            }else {
                try await queryProfiles().first!.profileId
            }
            UserDefaults.standard.setValue(profileId, forKey: "profileId")
            let selectedProfile = try await queryProfile(profileId: profileId)
            persistProfilePreferences(profile: selectedProfile)
            let activateProfileRequest = ActivateProfileRequest(profileId: profileId, pin: nil)
            let activateProfileResponse: ActivateProfileResponse = try await self.apiController.sendRequest(
                method: "POST",
                path: "v1/profile/\(profileId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)",
                data: activateProfileRequest
            )
            self.apiController.authorisationToken = activateProfileResponse.authToken
            self.profile = .success(selectedProfile)
        }catch let error {
            self.profile = .error(error)
        }
    }
    
    private func persistProfilePreferences(profile: Profile?) {
        guard let profile = profile else {
            return
        }
        
        UserDefaults.standard.set(profile.preferences.audioLanguage, forKey: AccountController.offlineAudioLanguageKey)
        UserDefaults.standard.set(profile.preferences.subtitlesLanguage, forKey: AccountController.offlineSubtitlesLanguageKey)
        UserDefaults.standard.set(profile.preferences.autoAdvance, forKey: AccountController.offlineAutoAdvanceKey)
    }
    
    private func getSelectedProfile(profileId: String?) async throws -> Profile? {
        if let profileId = profileId, let selectedProfile = try? await queryProfile(profileId: profileId) {
            return selectedProfile
        }else {
            let profiles = try await queryProfiles()
            return try await queryProfile(profileId: profiles.first!.profileId)
        }
    }
    
    func queryProfiles() async throws -> [Profile] {
        let response: ProfilesResponse = try await apiController.sendRequest(
            method: "GET",
            path: "v1/profile"
        )
        return response.items
    }
    
    private func queryProfile(profileId: String) async throws -> Profile {
        return try await apiController.sendRequest(
            method: "GET",
            path: "v1/profile/\(profileId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
        )
    }
    
    func updateProfile(profile: Profile) async throws {
        persistProfilePreferences(profile: profile)
        guard let profileId = profile.profileId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return
        }
        
        let _ = try await apiController.sendRequest(
            method: "PUT",
            path: "v1/profile/\(profileId)",
            data: profile
        )
    }
    
    func deleteProfile(profile: Profile) async throws {
        guard let profileId = profile.profileId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return
        }
        
        let _ = try await apiController.sendRequest(
            method: "DELETE",
            path: "v1/profile/\(profileId)",
            data: profile
        )
    }
    
    func saveProfile(profile: Profile) async throws {
        persistProfilePreferences(profile: profile)
        let response: SaveProfileResponse = try await apiController.sendRequest(
            method: "POST",
            path: "v1/profile",
            data: profile
        )
        profile.profileId = response.id
    }
    
    func getDetails() async throws -> AccountDetailsResponse {
        return try await apiController.sendRequest(
            method: "GET",
            path: "v2/user/profile"
        )
    }
    
    // Could an account not have an address? This could make the app crash
    func getAddress() async throws -> Address {
        let address: [Address] = try await apiController.sendRequest(
            method: "GET",
            path: "v2/user/address"
        )
        return address.last!
    }
    
    func updateBillingDetails(email: String, fullName: String, address: Address) async throws {
        let request = BillingDetailsRequest(address: address, fullName: fullName, email: email)
        let _: GeneralResponse = try await apiController.sendRequest(
            method: "PUT",
            path: "v2/user/billing-details",
            data: request,
            log: true
        )
    }
    
    func getCountries() async throws -> CountriesResponse {
        return try await apiController.sendRequest(
            method: "GET",
            path: "v3/i18n/country-codes"
        )
    }
    
    func addContinueWatching(episode: Episode) {
        guard case .success(let dashboard) = dashboard else {
            return
        }
        
        guard let continueWatchingBucket = dashboard.continueWatchingBucket else {
            return
        }
        
        withMutation(keyPath: \.dashboard) {
            if let lastWatchedEpisodeIndex = continueWatchingBucket.contentList.firstIndex(where: { $0.id == episode.id || $0.parentId == episode.parentId } ) {
                continueWatchingBucket.contentList.remove(at: lastWatchedEpisodeIndex)
            }
            
            continueWatchingBucket.contentList.insert(.episode(episode), at: 0)
        }
    }
}
