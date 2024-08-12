//
//  WatchlistView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 28/07/24.
//

import SwiftUI

struct WatchlistView: View {
    private let unattributedWatchlist: Watchlist
    @Environment(AccountController.self)
    private var accountController: AccountController
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    @Environment(RouterController.self)
    private var routerController: RouterController
    @State
    private var watchlist: AsyncResult<Watchlist> = .empty
    @State
    private var searchText: String = ""
    init(unattributedWatchlist: Watchlist) {
        self.unattributedWatchlist = unattributedWatchlist
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                switch(watchlist) {
                case .success(let watchlist):
                    loadedBody(geometry: geometry, watchlist: watchlist)
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
            .environment(\.defaultMinListHeaderHeight, 12)
            .listRowSpacing(12)
            .navigationTitle(unattributedWatchlist.name)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationBarItems(
                trailing: ShareLink(item: unattributedWatchlist.shareLink) {
                    Image(systemName: "square.and.arrow.up")
                }
            )
            .task {
                if case .empty = watchlist {
                    do {
                        self.watchlist = .loading
                        let watchlist = try await libraryController.getWatchlist(id: unattributedWatchlist.id, attributed: true)
                        self.watchlist = .success(watchlist)
                    }catch let error {
                        self.watchlist = .error(error)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func loadedBody(geometry: GeometryProxy, watchlist: Watchlist) -> some View {
        if let watchListContent = watchlist.content, !watchListContent.isEmpty {
            loadedPopulatedBody(geometry: geometry, watchlist: watchlist, watchListContent: watchListContent)
        }else {
            ExpandedView(geometry: geometry) {
                ContentUnavailableView(
                    "No content",
                    systemImage: "rectangle.stack.fill",
                    description: Text("Your watchlist's content will be displayed here")
                )
            }
        }
    }
    
    @ViewBuilder
    private func loadedPopulatedBody(geometry: GeometryProxy, watchlist: Watchlist, watchListContent: [DescriptableEntry]) -> some View {
        Section(header: Spacer(minLength: 0).listRowInsets(EdgeInsets())) {
            let filteredWatchListContent = searchText.isEmpty ? watchListContent : watchListContent.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
            if(filteredWatchListContent.isEmpty) {
                if let paging = watchlist.paging, paging.moreDataAvailable {
                    ExpandedView(geometry: geometry) {
                        LoadingView()
                    }.task {
                        do {
                            let watchlist = try await libraryController.getWatchlist(id: watchlist.id, attributed: true, from: watchlist)
                            self.watchlist = .success(watchlist)
                        } catch let error {
                            if(!error.isCancelledRequestError) {
                                self.watchlist = .error(error)
                            }
                        }
                    }
                    .id(UUID())
                }else {
                    ExpandedView(geometry: geometry) {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }else {
                ForEach(filteredWatchListContent) { watchlistEntry in
                    interactiveContextualEntryCard(watchlist: watchlist, watchlistEntry: watchlistEntry)
                }
                .onDelete {
                    for index in $0 {
                        guard let watchlistEntry = watchlist.content?.remove(at: index) else {
                            continue
                        }
                        
                        onDelete(watchlist: watchlist, watchlistEntry: watchlistEntry)
                    }
                    
                    if(watchlist.content?.isEmpty == true) {
                        watchlist.thumbnails = []
                        unattributedWatchlist.thumbnails = []
                    }
                }
                if(searchText.isEmpty && watchlist.paging?.moreDataAvailable == true) {
                    LoadingMoreView {
                        do {
                            let watchlist = try await libraryController.getWatchlist(id: watchlist.id, attributed: true, from: watchlist)
                            self.watchlist = .success(watchlist)
                        }catch let error {
                            self.watchlist = .error(error)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func interactiveContextualEntryCard(watchlist: Watchlist, watchlistEntry: DescriptableEntry) -> some View {
        interactiveEntryCard(watchlistEntry: watchlistEntry).contextMenu {
            if case .episode(let episode) = watchlistEntry {
                Button {
                    EpisodePlayer.open(
                        episodable: nil,
                        episode: episode,
                        accountController: accountController,
                        animeController: animeController
                    )
                } label: {
                    Label("Play", systemImage: "play")
                }
                
            }else {
                Button {
                    routerController.path.append(NestedPageType.home(watchlistEntry))
                } label: {
                    Label("Open", systemImage: "arrow.forward")
                }
            }
            
            if case .episode(let episode) = watchlistEntry, let season = episode.episodeInformation?.season {
                Button {
                    routerController.path.append(NestedPageType.home(.season(season)))
                } label: {
                    Label("Go to Anime", systemImage: "info.circle")
                }
            }
            
            Button {
                guard let index = watchlist.content?.firstIndex(of: watchlistEntry) else {
                    return
                }
                
                watchlist.content?.remove(at: index)
                
                onDelete(watchlist: watchlist, watchlistEntry: watchlistEntry)
                
                if(watchlist.content?.isEmpty == true) {
                    watchlist.thumbnails = []
                    unattributedWatchlist.thumbnails = []
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func interactiveEntryCard(watchlistEntry: DescriptableEntry) -> some View {
        if case .episode(let episode) = watchlistEntry {
            Button(
                action: {
                    EpisodePlayer.open(
                        episodable: nil,
                        episode: episode,
                        accountController: accountController,
                        animeController: animeController
                    )
                },
                label: {
                    entryCard(watchlistEntry: watchlistEntry)
                }
            )
            .buttonStyle(.plain)
        }else {
            NavigationLink(value: NestedPageType.home(watchlistEntry)) {
                entryCard(watchlistEntry: watchlistEntry)
            }
        }
    }
    
    @ViewBuilder
    private func entryCard(watchlistEntry: DescriptableEntry) -> some View {
        HStack(alignment: .top) {
            if let thumbnailUrl = watchlistEntry.coverUrl {
                NetworkImage(thumbnailEntry: thumbnailUrl)
                    .frame(width: 175, height: 100)
            } else {
                Image(systemName: "camera.metering.unknown")
                    .frame(width: 175, height: 100)
                    .background(Material.thin)
                    .cornerRadius(8)
            }
            
            Spacer()
                .frame(width: 12)
            
            VStack(alignment: .leading) {
                let title = if case .episode(let episode) = watchlistEntry {
                    episode.episodeInformation?.season?.parentTitle ?? "Unknown series"
                }else {
                    watchlistEntry.title
                }
                Text(title)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .lineLimit(4)
                
                let description = switch(watchlistEntry) {
                case .episode(let episode):
                    episode.title
                case .playlist(let playlist):
                    "\(playlist.episodesCount) video\(playlist.episodesCount != 1 ? "s" : "")"
                case .series(let series):
                    if let seasonCount = series.seasonCount {
                        "\(seasonCount) season\(seasonCount != 1 ? "s" : "")"
                    }else {
                        "Unknown seasons count"
                    }
                default:
                    ""
                }
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func onDelete(watchlist: Watchlist, watchlistEntry: DescriptableEntry) {
        Task {
            do {
                try await libraryController.removeWatchlistItem(watchlist: watchlist, watchlistEntry: watchlistEntry)
            }catch let error {
                print("Error: \(error)")
            }
        }
    }
}
