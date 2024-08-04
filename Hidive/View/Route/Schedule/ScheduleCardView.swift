//
//  ScheduleCardView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 18/07/24.
//

import SwiftUI

struct ScheduleCardView: View {
    private let entry: ScheduleBucketEntry
    init(entry: ScheduleBucketEntry) {
        self.entry = entry
    }
    
    var body: some View {
        Section(header: Text(entry.scheduleEntry.episodeDate, format: .dateTime)) {
            NavigationLink(value: PageType.scheduleEntry(entry)) {
                HStack(alignment: .top, spacing: 0) {
                    NetworkImage(url: entry.season.coverUrl)
                        .frame(width: 175, height: 100)
                    Spacer()
                        .frame(width: 12)
                    VStack(alignment: .leading) {
                        Text(entry.season.series!.title)
                            .lineLimit(2)
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                        Text("Episode \(entry.scheduleEntry.episodeNumber) | \(entry.scheduleEntry.airType.uppercased())")
                            .lineLimit(1)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }.buttonStyle(PlainButtonStyle())
        }
    }
}
