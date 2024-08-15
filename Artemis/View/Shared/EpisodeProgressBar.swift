//
//  EpisodeThumbnail.swift
//  Hidive
//
//  Created by Alessandro Autiero on 11/08/24.
//

import SwiftUI

struct EpisodeProgressBar: View {
    private let episode: Episode
    private let width: CGFloat
    private let height: CGFloat
    private let forceProgress: Bool
    init(episode: Episode, width: CGFloat, height: CGFloat = 4, forceProgress: Bool) {
        self.episode = episode
        self.width = width
        self.height = height
        self.forceProgress = forceProgress
    }
    
    // watchProgress : episode.duration = x : thumbnailWidth
    var body: some View {
        if let watchProgress = episode.watchProgress ?? (forceProgress ? 0 : nil) {
            let barHeight: CGFloat = 4
            let barWatchedWidth = max(CGFloat(watchProgress) * width / CGFloat(episode.duration), 10)
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
}
