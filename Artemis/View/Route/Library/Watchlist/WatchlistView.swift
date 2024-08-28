//
//  WatchlistView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 28/07/24.
//

import SwiftUI

struct WatchlistView: View {
    private static let headerId: String = "watchlistHeader"
    
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    @State
    private var contentResult: AsyncResult<Void> = .empty
    
    @State
    private var searchText: String = ""
    
    @State
    private var shouldScrollToHeader: Bool = false
    
    private let watchlist: Watchlist
    init(watchlist: Watchlist) {
        self.watchlist = watchlist
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                List {
                    switch(contentResult) {
                    case .success:
                        loadedBody(geometry: geometry)
                    case .loading, .empty:
                        ExpandedView(geometry: geometry) {
                            LoadingView()
                        }
                        .id(UUID())
                    case .error(let error):
                        ExpandedView(geometry: geometry) {
                            ErrorView(error: error)
                        }
                    }
                }
                .onAppear {
                    routerController.pathHandler = {
                        if(shouldScrollToHeader) {
                            withAnimation {
                                scrollProxy.scrollTo(WatchlistView.headerId, anchor: .center)
                            }
                            
                            return true
                        }
                        
                        return false
                    }
                }
                .environment(\.defaultMinListHeaderHeight, 12)
                .listRowSpacing(12)
                .navigationTitle(watchlist.name)
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                .navigationBarItems(
                    trailing: ShareLink(item: watchlist.shareLink) {
                        Image(systemName: "square.and.arrow.up")
                    }
                )
            }
        }
        .refreshable {
            if(accountController.profile.value == nil) {
                await accountController.login()
            }
            
            await loadWatchlist(refresh: true)
        }
        .task {
            if case .empty = contentResult {
                await loadWatchlist(refresh: false)
            }
        }
    }
    
    private func loadWatchlist(refresh: Bool) async {
        do {
            let startTime = Date.now.millisecondsSince1970
            self.contentResult = .loading
            let result = try await libraryController.getWatchlistContent(watchlist: watchlist)
            if(refresh) {
                let sleepTime = 750 - (Date.now.millisecondsSince1970 - startTime)
                if sleepTime > 0 {
                    try? await Task.sleep(for: .milliseconds(sleepTime))
                }
            }
            self.contentResult = .success(result)
        }catch let error {
            self.contentResult = .error(error)
        }
    }
    
    @ViewBuilder
    private func loadedBody(geometry: GeometryProxy) -> some View {
        if let watchListContent = watchlist.content, !watchListContent.isEmpty {
            loadedPopulatedBody(geometry: geometry, watchListContent: watchListContent)
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
    private func loadedPopulatedBody(geometry: GeometryProxy, watchListContent: [DescriptableEntry]) -> some View {
        Section(
            header: Spacer(minLength: 0)
                .listRowInsets(EdgeInsets())
                .onAppear {
                    self.shouldScrollToHeader = false
                }
                .onDisappear {
                    self.shouldScrollToHeader = true
                }
                .id(WatchlistView.headerId)
        ) {
            let filteredWatchListContent = searchText.isEmpty ? watchListContent : watchListContent.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
            if(filteredWatchListContent.isEmpty) {
                if let paging = watchlist.paging, paging.moreDataAvailable {
                    ExpandedView(geometry: geometry) {
                        LoadingView()
                    }.task {
                        do {
                            self.contentResult = .success(try await libraryController.getWatchlistContent(watchlist: watchlist))
                        } catch let error {
                            if(!error.isCancelledRequestError) {
                                self.contentResult = .error(error)
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
                }
                if(searchText.isEmpty && watchlist.paging?.moreDataAvailable == true) {
                    LoadingMoreView {
                        do {
                            self.contentResult = .success(try await libraryController.getWatchlistContent(watchlist: watchlist))
                        }catch let error {
                            self.contentResult = .error(error)
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
                        routerController: routerController,
                        accountController: accountController,
                        animeController: animeController
                    )
                } label: {
                    Label("Play", systemImage: "play")
                }
                
            }
            
            Button {
                if case .episode(let episode) = watchlistEntry, let season = episode.episodeInformation?.season {
                    routerController.path.append(NestedPageType.series(.season(season)))
                }else {
                    routerController.path.append(NestedPageType.series(watchlistEntry))
                }
            } label: {
                Label("Go to Anime", systemImage: "info.circle")
            }
            
            Button {
                guard let index = watchlist.content?.firstIndex(of: watchlistEntry) else {
                    return
                }
                
                watchlist.content?.remove(at: index)
                onDelete(watchlist: watchlist, watchlistEntry: watchlistEntry)
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
                        routerController: routerController,
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
            NavigationLink(value: NestedPageType.series(watchlistEntry)) {
                entryCard(watchlistEntry: watchlistEntry)
            }
        }
    }
    
    @ViewBuilder
    private func entryCard(watchlistEntry: DescriptableEntry) -> some View {
        HStack(alignment: .top) {
            if let thumbnailUrl = watchlistEntry.coverUrl {
                NetworkImage(
                    thumbnailEntry: thumbnailUrl,
                    width: 175, 
                    height: 100
                )
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
                    .lineLimit(3)
                
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
            try await libraryController.removeWatchlistItem(watchlist: watchlist, watchlistEntry: watchlistEntry)
        }
    }
}
