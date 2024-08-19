//
//  Schedule.swift
//   Artemis
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

struct ScheduleEntry: Identifiable, Equatable {
    let id: String
    let thumbnail: String
    let date: String
    let seriesTitle: String
    let episodeTitle: String
    let episodeType: String
    
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
