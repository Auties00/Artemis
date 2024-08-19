//
//  SearchEntryView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 21/07/24.
//

import SwiftUI

struct SearchEntryView: View {
    private let entry: SearchEntry
    init(entry: SearchEntry) {
        self.entry = entry
    }
    
    var body: some View {
        NavigationLink(value: NestedPageType.search(entry)) {
            HStack(alignment: .top, spacing: 0) {
                NetworkImage(
                    url: entry.coverUrl,
                    width: 175,
                    height: 100
                )
                .layoutPriority(1)
                Spacer()
                    .frame(width: 12)
                VStack(alignment: .leading) {
                    Text(entry.name)
                        .lineLimit(3)
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                    if let seasonsCount = entry.seasonsCount {
                        Text("\(seasonsCount) season\(seasonsCount != 1 ? "s" : "")")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }else if let videosCount = entry.videosCount {
                        Text("\(videosCount) video\(videosCount != 1 ? "s" : "")")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .layoutPriority(1)
                Spacer()
                    .frame(width: 12)
            }
        }
        .buttonStyle(.plain)
    }
}
