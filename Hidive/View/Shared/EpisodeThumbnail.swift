//
//  EpisodeThumbnail.swift
//  Hidive
//
//  Created by Alessandro Autiero on 11/08/24.
//

import SwiftUI

struct EpisodeThumbnail: View {
    private let episode: Episode
    private let width: CGFloat
    private let height: CGFloat
    private let fill: Bool
    private let forceProgress: Bool
    init(episode: Episode, width: CGFloat, height: CGFloat, fill: Bool, forceProgress: Bool) {
        self.episode = episode
        self.width = width
        self.height = height
        self.fill = fill
        self.forceProgress = forceProgress
    }
    
    var body: some View {
        let result = NetworkImage(thumbnailEntry: episode.thumbnailUrl, cornerRadius: 0, fill: fill)
            .frame(width: width, height: height)
        if let watchProgress = episode.watchProgress ?? (forceProgress ? 0 : nil) {
            result
                .overlay(
                episodeCardThumbnailProgress(watchProgress: watchProgress, duration: episode.duration),
                alignment: .bottom
            )
            .cornerRadius(8)
        }else {
            result
        }
    }
    
    @ViewBuilder
    private func episodeCardThumbnailProgress(watchProgress: Int, duration: Int) -> some View {
        // watchProgress : episode.duration = x : thumbnailWidth
        let barHeight: CGFloat = 4
        let barWatchedWidth = max(CGFloat(watchProgress) * width / CGFloat(duration), 10)
        let barRemainingWidth = width - barWatchedWidth
        HStack(spacing: 0) {
            Spacer()
                .frame(width: barWatchedWidth, height: barHeight)
                .background(.red)
            Spacer()
                .frame(width: barRemainingWidth, height: barHeight)
                .background(.secondary)
        }
    }
}
