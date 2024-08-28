//
//  WatchHistory.swift
//   Artemis
//
//  Created by Alessandro Autiero on 28/07/24.
//

import Foundation

class WatchHistoryDay: Identifiable, Equatable {
    let id: UUID
    let date: Date
    var episodes: [Episode]
    init(id: UUID? = nil, date: Date, episodes: [Episode]) {
        self.id = id ?? UUID()
        self.date = date
        self.episodes = episodes
    }
    
    static func ==(rhs: WatchHistoryDay, lhs: WatchHistoryDay) -> Bool {
        return rhs.id == lhs.id
    }
}
