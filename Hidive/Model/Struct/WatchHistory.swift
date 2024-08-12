//
//  WatchHistory.swift
//  Hidive
//
//  Created by Alessandro Autiero on 28/07/24.
//

import Foundation

struct WatchHistoryDay: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let episodes: [Episode]
    init(date: Date, episodes: [Episode]) {
        self.id = UUID()
        self.date = date
        self.episodes = episodes
    }
}
