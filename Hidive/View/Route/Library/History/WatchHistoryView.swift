//
//  WatchlistsView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 20/07/24.
//

import SwiftUI

struct WatchHistoryView: View {
    @Environment(AccountController.self) 
    private var accountController: AccountController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @State
    private var searchText: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            List {
                if(!accountController.isLoggedIn()) {
                    ExpandedView(geometry: geometry) {
                        ContentUnavailableView(
                            "No watch history",
                            systemImage: "clock.fill",
                            description: Text("Only registered users can view their watch history")
                        )
                    }
                }else {
                    switch(libraryController.watchHistory) {
                    case .success(let watchHistoryDays):
                        loadedBody(geometry: geometry, watchHistoryDays: watchHistoryDays)
                    case .loading, .empty:
                        ExpandedView(geometry: geometry) {
                            LoadingView()
                        }
                    case .error(let error):
                        ExpandedView(geometry: geometry) {
                            ErrorView(error: error)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
        .refreshable {
            if(accountController.profile.value == nil) {
                await accountController.login()
            }
            
            await libraryController.loadWatchHistory(reset: true)
        }
    }
    
    @ViewBuilder
    private func loadedBody(geometry: GeometryProxy, watchHistoryDays: [WatchHistoryDay]) -> some View {
        if(watchHistoryDays.isEmpty) {
            ExpandedView(geometry: geometry) {
                ContentUnavailableView(
                    "No watch history",
                    systemImage: "clock.fill",
                    description: Text("Your watch history will be displayed here")
                )
            }
        }else {
            let filteredWatchHistoryDays = searchText.isEmpty ? watchHistoryDays : watchHistoryDays.filter {
                $0.episodes.contains(where: {
                    $0.title.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText)
                })
            }
            if(filteredWatchHistoryDays.isEmpty) {
                if(libraryController.moreWatchHistoryAvailable) {
                    ExpandedView(geometry: geometry) {
                        LoadingView()
                    }.task {
                        await libraryController.loadWatchHistory()
                    }
                    .id(UUID())
                }else {
                    ExpandedView(geometry: geometry) {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }else {
                ForEach(filteredWatchHistoryDays) { watchHistoryDay in
                    Section(header: Text(watchHistoryDay.date.toRelativeString(includeHour: false))) {
                        LazyVStack(alignment: .leading) {
                            let filteredEpisodes = searchText.isEmpty ? watchHistoryDay.episodes : watchHistoryDay.episodes.filter {
                                $0.title.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText)
                            }
                            ForEach(filteredEpisodes) { entry in
                                let season = entry.episodeInformation!.season
                                Button(
                                    action: {
                                        EpisodePlayer.open(
                                            episodable: season,
                                            episode: entry,
                                            accountController: accountController,
                                            animeController: animeController
                                        )
                                    },
                                    label: {
                                        HStack(alignment: .top, spacing: 0) {
                                            NetworkImage(thumbnailEntry: entry.thumbnailUrl)
                                                .frame(width: 175, height: 100)
                                            Spacer()
                                                .frame(width: 12)
                                            VStack(alignment: .leading) {
                                                Text(season?.series?.title ?? "Unknown")
                                                    .font(.system(size: 20))
                                                    .fontWeight(.bold)
                                                    .lineLimit(2)
                                                Text(entry.title)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(3)
                                            }
                                        }
                                    }
                                )
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                if(libraryController.moreWatchHistoryAvailable) {
                    LoadingMoreView {
                        await libraryController.loadWatchHistory()
                    }
                    .id(UUID())
                }
            }
        }
    }
}
