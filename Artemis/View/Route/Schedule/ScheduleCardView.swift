//
//  ScheduleCardView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 18/07/24.
//

import SwiftUI
import AlertToast

struct ScheduleCardView: View {
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    @Environment(\.colorScheme)
    private var colorScheme
    
    private let headerId: String?
    private let entry: ScheduleEntry
    private let addToWatchlistHandler: (DescriptableEntry) -> Void
    init(headerId: String?, entry: ScheduleEntry, addToWatchlistHandler: @escaping (DescriptableEntry) -> Void) {
        self.headerId = headerId
        self.entry = entry
        self.addToWatchlistHandler = addToWatchlistHandler
    }
    
    var body: some View {
        Section(header: header()) {
            NavigationLink(value: NestedPageType.schedule(entry.id)) {
                HStack(alignment: .top, spacing: 0) {
                    NetworkImage(
                        url: entry.thumbnail,
                        width: 175,
                        height: 100
                    )
                    .layoutPriority(1)
                    Spacer()
                        .frame(width: 12)
                    VStack(alignment: .leading) {
                        Text(entry.seriesTitle)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                        Text("\(entry.episodeTitle) | \(entry.episodeType.capitalized)")
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .layoutPriority(1)
                    Spacer()
                        .frame(width: 12)
                }
            }
            .contextMenu {
                contextMenu()
            }
        }
    }
    
    @ViewBuilder
    private func header() -> some View {
        let header = Text(entry.date)
        if let headerId = headerId {
            header.id(headerId)
        }else {
            header
        }
    }
    
    @ViewBuilder
    private func contextMenu() -> some View {
        Button {
            openAnime()
        } label: {
            Label("Go to Anime", systemImage: "info.circle")
        }
        
        Button {
            addToWatchlist()
        } label: {
            Label("Add to Watchlist", systemImage: "list.star")
        }
    }
    
    private func openAnime() {
        routerController.path.append(NestedPageType.schedule(entry.id))
    }
    
    private func addToWatchlist() {
        Task {
            guard let episodeIdString = entry.id.split(separator: "#", maxSplits: 2).last else {
                return
            }
            
            guard let episodeId = Int(String(episodeIdString)) else {
                return
            }
            
            let episode = try await animeController.getEpisode(id: episodeId, includePlayback: false)
            let series = try await animeController.getSeries(id: episode.parentId)
            self.addToWatchlistHandler(.series(series))
        }
    }
}
