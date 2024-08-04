//
//  AnimeController.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import Foundation

class AnimeController: ObservableObject {
    private let apiController: ApiController
    init(apiController: ApiController) {
        self.apiController = apiController
    }
    
    func getSeries(id: Int) async throws -> Series {
        return try await self.apiController.sendRequest(
            method: "GET",
            path: "v4/series/\(id)?rpp=20"
        )
    }
    
    func getSeason(id: Int) async throws -> Season {
        return try await self.apiController.sendRequest(
            method: "GET",
            path: "v4/season/\(id)?rpp=20"
        )
    }
    
    func getEpisode(id: Int) async throws -> Episode {
        return try await self.apiController.sendRequest(
            method: "GET",
            path: "v2/vod/\(id)"
        )
    }
    
    func getVod(id: Int) async throws -> Vod {
        return try await self.apiController.sendRequest(
            method: "GET",
            path: "v2/vod/\(id)?includePlaybackDetails=URL"
        )
    }
    
    func getPlayback(vod: Vod) async throws -> Playback {
        return try await self.apiController.sendRequest(
            method: "GET",
            url: vod.playerURLCallback ?? vod.playerUrlCallback!
        )
    }
}
