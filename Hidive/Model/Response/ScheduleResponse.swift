//
//  ScheduleResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 18/07/24.
//

import Foundation

struct ScheduleResponse: Decodable {
    let entries: [ScheduleEntry]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.entries = try container.decode([ScheduleEntry].self)
    }
}

struct ScheduleBucketEntry: Identifiable, Equatable, Hashable {
    let id: UUID = UUID()
    let scheduleEntry: ScheduleEntry
    let season: Season
}

