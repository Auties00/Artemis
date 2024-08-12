//
//  ScheduleCardView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 18/07/24.
//

import SwiftUI
import AlertToast

struct ScheduleCardView: View {
    private let entry: ScheduleEntry
    private let addToWatchlistHandler: (DescriptableEntry?) -> Void
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    @Environment(RouterController.self)
    private var routerController: RouterController
    init(entry: ScheduleEntry, addToWatchlistHandler: @escaping (DescriptableEntry?) -> Void) {
        self.entry = entry
        self.addToWatchlistHandler = addToWatchlistHandler
    }
    
    var body: some View {
        Section(header: Text(entry.date)) {
            NavigationLink(value: NestedPageType.schedule(entry.id)) {
                HStack(alignment: .top, spacing: 0) {
                    NetworkImage(url: entry.thumbnail)
                        .frame(width: 175, height: 100)
                        .layoutPriority(1)
                    Spacer()
                        .frame(width: 12)
                    VStack(alignment: .leading) {
                        Text(entry.seriesTitle)
                            .lineLimit(3)
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                        Text("\(entry.episodeTitle) | \(entry.episodeType.capitalized)")
                            .lineLimit(2)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .layoutPriority(1)
                    Spacer()
                        .frame(width: 12)
                }
                .contextMenu {
                    Button {
                        routerController.path.append(NestedPageType.schedule(entry.id))
                    } label: {
                        Label("Go to Anime", systemImage: "info.circle")
                    }
                    
                    Button {
                        Task {
                            do {
                                guard let episodeIdString = entry.id.split(separator: "#", maxSplits: 2).last else {
                                    self.addToWatchlistHandler(nil)
                                    return
                                }
                                
                                guard let episodeId = Int(String(episodeIdString)) else {
                                    self.addToWatchlistHandler(nil)
                                    return
                                }
                                
                                let episode = try await animeController.getEpisode(id: episodeId, includePlayback: false)
                                let series = try await animeController.getSeries(id: episode.parentId)
                                self.addToWatchlistHandler(.series(series))
                            }catch {
                                self.addToWatchlistHandler(nil)
                            }
                        }
                    } label: {
                        Label("Add to Watchlist", systemImage: "list.star")
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}
