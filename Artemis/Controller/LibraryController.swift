//
//  LibraryController.swift
//   Artemis
//
//  Created by Alessandro Autiero on 27/07/24.
//

import Foundation
import SwiftUI
import AVKit

@Observable
class LibraryController {
    private let apiController: ApiController
    private let animeController: AnimeController
    var watchlists: AsyncResult<Watchlists> = .empty
    var watchHistory: AsyncResult<[WatchHistoryDay]> = .empty
    private var watchHistoryPages: Int = 1
    private var currentWatchHistoryPage: Int = 1
    var moreWatchHistoryAvailable: Bool {
        return currentWatchHistoryPage <= watchHistoryPages
    }
    var downloads: [Int: DownloadedEntry] = [:]
    private var downloadsWriteLock = NSLock()
    var activeDownloads: [Int:ActiveDownload] = [:]
    private var activeDownloadsLock: NSLock = NSLock()
    private var downloadsJson: URL {
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("hidiveDownloads.json")
    }
    private var createdDownloads: Set<Int> = Set()
    init(apiController: ApiController, animeController: AnimeController) {
        self.apiController = apiController
        self.animeController = animeController
        if let decoded = try? JSONDecoder().decode([Int: DownloadedEntry].self, from: Data(contentsOf: downloadsJson)) {
            self.downloads = decoded
        }
    }
    
    func loadWatchlists(lastSeen: String? = nil) async {
        do {
            let isRefresh = lastSeen == nil && watchlists.value != nil
            let startTime = Date.now.millisecondsSince1970
            
            if(isRefresh) {
                watchlists = .loading
            }
            
            let response: WatchlistsResponse = try await apiController.sendRequest(
                method: "GET",
                path: "v3/user/watchlist?\(lastSeen == nil ? "" : "lastSeen=\(lastSeen!)&")rpp=25"
            )
            
            if(isRefresh) {
                let sleepTime = 750 - (Date.now.millisecondsSince1970 - startTime)
                if sleepTime > 0 {
                    try? await Task.sleep(for: .milliseconds(sleepTime))
                }
            }
            
            if case .success(let previousWatchlists) = watchlists {
                previousWatchlists.update(response: response)
            }else {
                watchlists = .success(Watchlists(response: response))
            }
        }catch let error {
            watchlists = .error(error)
        }
    }
    
    func getWatchlistContent(watchlist: Watchlist) async throws {
        let lastSeen = if let paging = watchlist.paging, watchlist.content != nil {
            "lastSeen=\(paging.lastSeen)&"
        }else {
            ""
        }
        
        let result: Watchlist = try await apiController.sendRequest(
            method: "GET",
            path: "v4/user/watchlist/\(watchlist.id)?\(lastSeen)rpp=20"
        )

        try await attributeWatchlist(watchlist: result)
        watchlist.thumbnails = result.thumbnails
        let nextContent = result.content ?? []
        if var watchlistContent = watchlist.content {
            watchlistContent.append(contentsOf: nextContent)
        }else {
            watchlist.content = nextContent
        }
    }
    
    // Cache the episodes that don't have metadata
    // Replace seasons with series
    // Remove duplicates
    private func attributeWatchlist(watchlist: Watchlist) async throws {
        let content = try await withThrowingTaskGroup(of: DescriptableEntry?.self) { group in
            for bucketEntry in watchlist.content ?? [] {
                group.addTask {
                    switch(bucketEntry) {
                    case .season(let season):
                        if let seriesId = season.series?.id {
                            let series = try await self.animeController.getSeries(id: seriesId)
                            return .series(series)
                        }else {
                            return nil
                        }
                    case .episode(let episode):
                        let episode = try await self.animeController.getEpisode(id: episode.id, includePlayback: false)
                        return .episode(episode)
                    default:
                        return bucketEntry
                    }
                }
            }
            
            var resultsIds: Set<Int> = []
            var results: [DescriptableEntry] = []
            while let result = try await group.next() {
                if let result = result, !resultsIds.contains(result.id) {
                    results.append(result)
                    resultsIds.insert(result.id)
                }
            }
            return results
        }
        watchlist.content = content
    }
    
    func loadWatchHistory(reset: Bool = false) async {
        do {
            let startTime = Date.now.millisecondsSince1970
            if(reset) {
                watchHistory = .loading
                watchHistoryPages = 1
                currentWatchHistoryPage = 1
            } else if(currentWatchHistoryPage == 1) {
                watchHistory = .loading
            }
            
            let response: WatchHistoryResponse = try await apiController.sendRequest(
                method: "GET",
                path: "v2/customer/history/vod?p=\(currentWatchHistoryPage)&rpp=10"
            )
            for episode in response.episodes {
                if let episodeInformation = episode.episodeInformation {
                    let season: Season = try await animeController.getSeason(id: episodeInformation.seasonId)
                    episode.episodeInformation?.season = season
                }
            }
            
            let groupedEpisodes = Dictionary(grouping: response.episodes.filter { $0.watchedAt != nil } , by: getEpisodeDay)
                .sorted { $0.key > $1.key }
                .map { WatchHistoryDay(date: $0, episodes: $1) }
            
            if(reset) {
                let sleepTime = 750 - (Date.now.millisecondsSince1970 - startTime)
                if sleepTime > 0 {
                    try? await Task.sleep(for: .milliseconds(sleepTime))
                }
            }
            
            if case .success(let previousEpisodes) = watchHistory {
                watchHistory = .success(previousEpisodes + groupedEpisodes)
            }else {
                watchHistory = .success(groupedEpisodes)
            }
            
            watchHistoryPages = response.totalPages
            currentWatchHistoryPage += 1
        }catch let error {
            if(watchHistoryPages == 1 || !error.isCancelledRequestError) {
                watchHistory = .error(error)
            }
        }
    }
    
    private func getEpisodeDay(episode: Episode) -> Date {
        let secondsInDay: Int64 = 86400
        let days = episode.watchedAt! / 1000 / secondsInDay * secondsInDay
        return Date(timeIntervalSince1970: Double(days))
    }
    
    func createWatchlist(name: String) async throws {
        let request = CreateWatchlistRequest(name: name)
        let response: CreateWatchlistResponse = try await apiController.sendRequest(
            method: "POST",
            path: "v3/user/watchlist",
            data: request
        )
        if case .success(let watchlists) = watchlists {
            let watchlist: Watchlist = try await apiController.sendRequest(
                method: "GET",
                path: "v3/user/watchlist/\(response.id)?rpp=20"
            )
            watchlists.data.insert(watchlist, at: 0)
        }
    }
    
    func renameWatchlist(watchlist: Watchlist, name: String) async throws {
        let request = CreateWatchlistRequest(name: name)
        let _ = try await apiController.sendRequest(
            method: "PUT",
            path: "v3/user/watchlist/\(watchlist.id)",
            data: request
        )
        watchlist.name = name
    }
    
    func deleteWatchlist(watchlist: Watchlist) async throws {
        let _ = try await apiController.sendRequest(
            method: "DELETE",
            path: "v3/user/watchlist/\(watchlist.ownerExternalId)/\(watchlist.id)"
        )
    }
    
    func addWatchlistItem(watchlist: Watchlist, whatchlistEntry: DescriptableEntry) async throws {
        let content = AddWatchlistItemContent(id: String(whatchlistEntry.id), contentType: whatchlistEntry.type)
        let request = AddWatchlistItemRequest(content: [content])
        let _ = try await apiController.sendRequest(
            method: "POST",
            path: "v4/user/watchlist/\(watchlist.id)/content",
            data: request
        )
        if var content = watchlist.content {
            if watchlist.thumbnails.isEmpty, let thumbnail = whatchlistEntry.coverUrl {
                watchlist.thumbnails = [thumbnail]
            }
            
            content.append(whatchlistEntry)
        }else {
            try await getWatchlistContent(watchlist: watchlist)
        }
    }
    
    func removeWatchlistItem(watchlist: Watchlist, watchlistEntry: DescriptableEntry) async throws {
        let _ =  try await apiController.sendRequest(
            method: "DELETE",
            path: "v4/user/watchlist/\(watchlist.id)/content/\(watchlistEntry.type)/\(watchlistEntry.id)"
        )
        if(watchlist.content?.isEmpty == true) {
            watchlist.thumbnails = []
        }
    }
    
    func addDownload(downloadEntry: DownloadableEntry) async throws {
        if(activeDownloads[downloadEntry.id] != nil) {
            return
        }
        
        let activeDownload = ActiveDownload()
        activeDownloadsLock.withLock {
            activeDownloads[downloadEntry.id] = activeDownload
        }
        Task.detached {
            try await self.saveDownload(downloadEntry: downloadEntry)
        }
        switch(downloadEntry) {
        case .episode(let episode):
            try await downloadEpisode(activeDownload: activeDownload, episode: episode)
        case .playlist(let playlist):
            try await downloadEpisodes(activeDownload: activeDownload, episodable: playlist)
        case .season(let season):
            try await downloadEpisodes(activeDownload: activeDownload, episodable: season)
        }
    }
    
    private func downloadEpisodes(activeDownload: ActiveDownload, episodable: Episodable) async throws {
        // We could pass the callback directly to downloadEpisode,
        // but then if the user clicks on the season download button
        // when there is a single episode left to download, that is already being downloaded,
        // no tasks are started and the progress of the season downloader remains at zero
        activeDownload.childHandler = {
            var totalProgress = 0.0
            var episodesCount = 0.0
            var allCancelled = true
            for episode in episodable.episodes ?? [] {
                if let activeDownload = self.activeDownloads[episode.id], !activeDownload.cancelled {
                    totalProgress += activeDownload.progress
                    episodesCount += 1
                    allCancelled = false
                }
            }
            if(allCancelled) {
                activeDownload.cancelled = true
                activeDownload.downloadTask?.cancel()
                let _ = self.activeDownloadsLock.withLock {
                    self.activeDownloads.removeValue(forKey: episodable.id)
                }
            }else {
                activeDownload.progress = totalProgress / episodesCount
            }
        }
        
        let episodes = episodable.episodes?.filter { episode in
            !episode.isSaved && activeDownloads[episode.id] == nil
        } ?? []
        for episode in episodes {
            activeDownload.childrenIds.append(episode.id)
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for episode in episodes {
                let episodeActiveDownload = ActiveDownload()
                activeDownloadsLock.withLock {
                    self.activeDownloads[episode.id] = activeDownload
                }
                group.addTask(priority: .high) {
                    try await self.downloadEpisode(activeDownload: episodeActiveDownload, episode: episode)
                }
            }
            
            try await group.waitForAll()
        }
    }
    
    private func downloadEpisode(activeDownload: ActiveDownload, episode: Episode) async throws {
        guard let hlsStream = try await self.animeController.getPersistentFairPlayback(episodeId: episode.id) else {
            return
        }
        
        guard let asset = FairplayContentKeySessionHandler.createAsset(hlsStream: hlsStream) else {
            return
        }
        
        let resource = FairplayResource.download(hlsStream)
        let subtitlesInjector = SubtitlesResourceInjector(resource: resource)
        let fairplaySession = AVContentKeySession(keySystem: .fairPlayStreaming)
        fairplaySession.addContentKeyRecipient(asset)
        asset.resourceLoader.preloadsEligibleContentKeys = true
        asset.resourceLoader.setDelegate(subtitlesInjector, queue: DispatchQueue.main)
        let fairplayHandler = FairplayContentKeySessionHandler(resource: resource)
        fairplaySession.setDelegate(fairplayHandler, queue: DispatchQueue.main)
        
        let taskIdentifier = UUID().uuidString
        let configuration = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).download.\(taskIdentifier)")
        let resourceSaver = OfflineResourceSaver(episode: episode)
        let downloadSession = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: resourceSaver, delegateQueue: OperationQueue.main)
        let downloadTaskConfig = AVAssetDownloadConfiguration(asset: asset, title: taskIdentifier)
        let downloadTask = downloadSession.makeAssetDownloadTask(downloadConfiguration: downloadTaskConfig)
        activeDownload.downloadTask = downloadTask
        activeDownload.subtitlesInjector = subtitlesInjector
        activeDownload.fairplaySessionHandler = fairplayHandler
        activeDownload.fairplaySession = fairplaySession
        activeDownload.resourceSaver = resourceSaver
        let observer = DownloadProgressObserver { value in
            if(!activeDownload.cancelled) {
                if(value == 1) {
                    episode.isSaved = true
                    self.activeDownloadsLock.withLock {
                        let _ = self.activeDownloads.removeValue(forKey: episode.id)
                    }
                }
                
                activeDownload.progress = value
            }
            
            if let seasonId = episode.episodeInformation?.seasonId, let childHandler = self.activeDownloads[seasonId]?.childHandler {
                childHandler()
            }
        }
        downloadTask.progress.addObserver(observer, forKeyPath: "fractionCompleted", context: nil)
        activeDownload.observer = observer

        await MainActor.run {
            activeDownloadsLock.withLock {
                self.activeDownloads[episode.id] = activeDownload
            }
        }
        
        downloadTask.resume()
    }
    
    // POSSIBLE IMPROVEMENT: Find a way to determine if updaring the entry is necessary
    private func saveDownload(downloadEntry: DownloadableEntry) async throws {
        guard let downloadedEntry = try await createDownload(downloadEntry: downloadEntry) else {
            return
        }
        
        downloadsWriteLock.withLock {
            self.downloads[downloadEntry.parentId] = downloadedEntry
        }
        serializeDownloads()
    }
    
    private func serializeDownloads() {
        if let data = try? JSONEncoder().encode(self.downloads) {
            try? data.write(to: downloadsJson)
        }
    }
    
    // Consider that DownloadableEntry can be a season, a playlist or an episode
    // DownloadedEntry can be a series or a playlist
    // If the incoming DownloadableEntry is a season, checking if the previously cached DownloadedEntry is up to date is too complicated
    // (ex. new season added, new episodes added, episode thumbnail changed, episode description changed, ...)
    // Checking for playlists is easier, but episodes have the same problem as we still have to check the parent series
    // To save up time, we assume that the DownloadedEntry is up to date if it was downloaded in the current app's lifecycle
    private func createDownload(downloadEntry: DownloadableEntry) async throws -> DownloadedEntry? {
        if(createdDownloads.contains(downloadEntry.id)) {
            return nil
        }
        
        createdDownloads.insert(downloadEntry.id)
        if case .playlist(let playlist) = downloadEntry {
            let playlist = try await animeController.getPlaylist(id: playlist.id)
            await playlist.saveThumbnails()
            return .playlist(playlist)
        }
        
        let series = try await animeController.getSeries(id: downloadEntry.parentId)
        await series.saveThumbnails()
        var seasons: [Season] = []
        for season in series.seasons ?? [] {
            let season = try await animeController.getSeason(id: season.id)
            await season.saveThumbnails()
            seasons.append(season)
        }
        series.seasons = seasons
        return .series(series)
    }
    
    func removeDownload(downloadedEntry: DownloadedEntry) {
        switch(downloadedEntry) {
        case .playlist(let playlist):
            removeDownload(episodable: playlist)
        case .series(let series):
            for season in series.seasons ?? [] {
                removeDownload(episodable: season)
            }
        }
    }
    
    func removeAndCancelDownload(episode: Episode, serialize: Bool = true) {
        if let activeDownload = activeDownloads[episode.id] {
            activeDownload.cancelled = true
            activeDownload.downloadTask?.cancel()
        }
        
        episode.isSaved = false
        OfflineResourceSaver.deleteResource(id: episode.id)
        let _ = activeDownloadsLock.withLock {
            activeDownloads.removeValue(forKey: episode.id)
        }
        if(serialize) {
            serializeDownloads()
        }
    }
    
    func cancelDownload(episodable: Episodable) {
        if let activeDownload = activeDownloads[episodable.id] {
            activeDownload.cancelled = true
            activeDownload.downloadTask?.cancel()
            for childId in activeDownload.childrenIds {
                if let childActiveDownload = activeDownloads[childId] {
                    childActiveDownload.cancelled = true
                    childActiveDownload.downloadTask?.cancel()
                    OfflineResourceSaver.deleteResource(id: childId)
                }
            }
            
            OfflineResourceSaver.deleteResource(id: episodable.id)
            let _ = activeDownloadsLock.withLock {
                activeDownloads.removeValue(forKey: episodable.id)
                for childId in activeDownload.childrenIds {
                    activeDownloads.removeValue(forKey: childId)
                }
            }
        
            serializeDownloads()
        }
    }
    
    func removeDownload(episodable: Episodable) {
        if let activeDownload = activeDownloads[episodable.id] {
            activeDownload.cancelled = true
            activeDownload.downloadTask?.cancel()
        }
        
        OfflineResourceSaver.deleteResource(id: episodable.parentId)
        let _ = activeDownloadsLock.withLock {
            activeDownloads.removeValue(forKey: episodable.parentId)
        }
        
        for episode in episodable.episodes ?? [] {
            removeAndCancelDownload(episode: episode, serialize: false)
        }
        
        serializeDownloads()
    }
    
    func pauseDownload(id: Int) {
        if let activeDownload = activeDownloads[id] {
            activeDownload.downloadTask?.suspend()
            activeDownload.paused = true
        }
    }
    
    func resumeDownload(id: Int) {
        if let activeDownload = activeDownloads[id] {
            activeDownload.downloadTask?.resume()
            activeDownload.paused = false
        }
    }
}

private class DownloadProgressObserver: NSObject {
    private let onProgress: (Double) -> Void
    init(onProgress: @escaping (Double) -> Void) {
        self.onProgress = onProgress
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let progress = object as? Progress else {
            return
        }
        
        onProgress(progress.fractionCompleted)
    }
}
