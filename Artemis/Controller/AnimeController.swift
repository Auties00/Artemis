//
//  AnimeController.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import Foundation

@Observable
class AnimeController {
    private let apiController: ApiController
    private var seriesCache: [Int:Task<Series, Error>] = [:]
    private let seriesCacheLock: NSLock = NSLock()
    private var seasonsCache: [Int:Task<Season, Error>] = [:]
    private let seasonsCacheLock: NSLock = NSLock()
    private var playlistsCache: [Int:Task<Playlist, Error>] = [:]
    private let playlistsCacheLock: NSLock = NSLock()
    private var episodeCache: [Int:Task<Episode, Error>] = [:]
    private let episodeCacheLock: NSLock = NSLock()
    init(apiController: ApiController) {
        self.apiController = apiController
    }
    
    func getSeries(id: Int) async throws -> Series {
        let task = seriesCacheLock.withLock {
            if let cached = seriesCache[id]  {
                return cached
            }
            
            let result = Task<Series, Error> {
                try await self.apiController.sendRequest(
                    method: "GET",
                    path: "v4/series/\(id)?rpp=25"
                )
            }
            
            seriesCache[id] = result
            return result
        }
        
        do {
            return try await task.value
        }catch let error {
            let _ = episodeCacheLock.withLock {
                seriesCache.removeValue(forKey: id)
            }
            throw error
        }
    }
    
    // We need all the episodes for the download button next to the season selector
    func getSeason(id: Int) async throws -> Season {
        let task = seasonsCacheLock.withLock {
            if let cached = seasonsCache[id] {
                return cached
            }
            
            let result = Task<Season, Error> {
                var season: Season = try await self.apiController.sendRequest(
                    method: "GET",
                    path: "v4/season/\(id)?rpp=25"
                )
                
                while let paging = season.paging, paging.moreDataAvailable {
                    let additionalSeason: Season = try await self.apiController.sendRequest(
                        method: "GET",
                        path: "v4/season/\(id)?lastSeen=\(paging.lastSeen)&rpp=25"
                    )
                    if let previousEpisodes = season.episodes {
                        additionalSeason.episodes?.insert(contentsOf: previousEpisodes, at: 0)
                    }
                    season = additionalSeason
                }
                
                for episode in season.episodes ?? [] {
                    if var episodeInformation = episode.episodeInformation {
                        episodeInformation.season = season
                        episode.episodeInformation = episodeInformation
                    }
                }

                return season
            }

            seasonsCache[id] = result
            return result
        }
        
        do {
            return try await task.value
        }catch let error {
            let _ = episodeCacheLock.withLock {
                seasonsCache.removeValue(forKey: id)
            }
            throw error
        }
    }

    func getPlaylist(id: Int) async throws -> Playlist {
        let task = playlistsCacheLock.withLock {
            if let cached = playlistsCache[id]  {
                return cached
            }
            
            let result: Task<Playlist, Error> = Task {
                try await self.apiController.sendRequest(
                    method: "GET",
                    path: "v4/playlist/\(id)?rpp=25"
                )
            }
            
            playlistsCache[id] = result
            return result
        }
        
        do {
            return try await task.value
        }catch let error {
            let _ = episodeCacheLock.withLock {
                playlistsCache.removeValue(forKey: id)
            }
            throw error
        }
    }
    
    func getEpisode(id: Int, includePlayback: Bool) async throws -> Episode {
        let task = episodeCacheLock.withLock {
            if let cached = episodeCache[id], !includePlayback  {
                return cached
            }
            
            let result: Task<Episode, Error> = Task {
                let episode: Episode = try await self.apiController.sendRequest(
                    method: "GET",
                    path: "v2/vod/\(id)\(includePlayback ? "?includePlaybackDetails=URL" : "")"
                )
                if let episodeInformation = episode.episodeInformation {
                    let season: Season = try await getSeason(id: episodeInformation.seasonId)
                    episode.episodeInformation?.season = season
                }
                return episode
            }
            
            episodeCache[id] = result
            return result
        }
        
        do {
            return try await task.value
        }catch let error {
            let _ = episodeCacheLock.withLock {
                episodeCache.removeValue(forKey: id)
            }
            throw error
        }
    }
    
    func getFairplayPlayback(episode: Episode) async throws -> PlaybackEntry? {
        let playback: Playback = try await self.apiController.sendRequest(
            method: "GET",
            url: episode.playerUrlCallback
        )
        return playback.hls.first(where: {
            $0.drm.keySystems.contains("FAIRPLAY")
        })
    }
    
    func getPersistentFairPlayback(episodeId: Int) async throws -> PlaybackEntry? {
        // I have absolutely no idea what this sessionId is supposed to be
        // When I analyzed the app's traffic it just used it in this request
        // I couldn't find it anywhere else: no cookies, no storage, no nothing
        // So it's either the Fairplay sessionId, which on ios is 16 bytes of data so it could be read as a UUID, or a random identifier
        // It doesn't look like it changes anything, so I just went with the random id route
        // Still without it the request will fail
        let downloadResponse: DownloadResponse = try await self.apiController.sendRequest(
            method: "GET",
            path: "v2/download/vod/\(episodeId)/HIGH/eng?sessionId=\(UUID().uuidString)"
        )
        let playback: Playback = try await self.apiController.sendRequest(
            method: "GET",
            url: downloadResponse.playerUrlCallback
        )
        return playback.hls.first(where: {
            $0.drm.keySystems.contains("FAIRPLAY")
        })
    }
    
    func getEpisodeHeaders() -> [String:String] {
        return apiController.prepareHeaders()
    }
    
    func getAdjacentEpisodes(id: Int, size: Int = 5) async throws -> AdjacentEpisodesResponse {
        return try await self.apiController.sendRequest(
            method: "GET",
            path: "v4/vod/\(id)/adjacent?size=\(size)"
        )
    }
    
    func saveWatchProgress(cid: String, id: Int, progress: Int, last: Bool) async throws {
        let request = WatchProgressRequest(video: id, cid: cid, startedAt: Date.now.millisecondsSince1970, action: 2, ctx: 0, progress: progress, nature: last ? "last" : nil)
        let _ = try await apiController.sendRequest(
            method: "POST",
            url: "https://guide.imggaming.com/prod",
            data: [request]
        )
    }
    
    func clearCache() {
        seriesCache.removeAll()
        seasonsCache.removeAll()
        playlistsCache.removeAll()
        episodeCache.removeAll()
    }
}
