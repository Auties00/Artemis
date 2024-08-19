//
//  SeriesView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 18/07/24.
//

import SwiftUI
import AVFoundation

struct SeriesView: View {
    private static let defaultImageHeight: CGFloat = 573.3333333333334
    private static let scrollableCoordinateSpace = "series"
    
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @Environment(ConnectivityController.self)
    private var connectivityController: ConnectivityController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State
    private var id: Any
    
    @State
    private var name: String
    
    @State
    private var navigationBarTitle = ""
    
    @State
    private var selectedSeasonNumber: Int
    
    @State
    private var holder: AsyncResult<Holder>
    
    @State
    private var showDescription: Bool = false
    
    @State
    private var scrollPosition: Int?
    
    @State
    private var thumbnailHeight: CGFloat = SeriesView.defaultImageHeight
    
    @State
    private var thumbnailOpacity: Double = 1
    
    @State
    private var lastOverscroll: CGFloat = 0
    
    @State
    private var navigationBarOpacity: CGFloat = 0
    
    @State
    private var shareText: SharableLink?
    
    @State
    private var shouldScrollToHeader: Bool = false
    
    private let playlist: Bool
    init(id: Int, name: String, playlist: Bool, selectedSeasonNumber: Int? = nil) {
        self._id = State(initialValue: id)
        self.playlist = playlist
        self._name = State(initialValue: name)
        self._holder = State(initialValue: .empty)
        self._selectedSeasonNumber = State(initialValue: selectedSeasonNumber ?? 1)
    }
    
    // Download
    init(downloadedEntry: DownloadedEntry, selectedSeasonNumber: Int? = nil) {
        self._id = State(initialValue: downloadedEntry.id)
        let series: Series? = if case .series(let series) = downloadedEntry {
            series
        }else {
            nil
        }
        self.playlist = series == nil
        self._name = State(initialValue: downloadedEntry.wrappedValue.parentTitle)
        let episodable: EpisodableEntry = switch(downloadedEntry) {
        case .series(let series):
                .season(series.seasons![0]) // Guaranteed
        case .playlist(let playlist):
                .playlist(playlist)
        }
        self._holder = State(initialValue: .success(Holder(series: series, episodable: episodable, download: true)))
        self._selectedSeasonNumber = State(initialValue: selectedSeasonNumber ?? 1)
    }
    
    // Schedule
    init(identifier: String) {
        self._id = State(initialValue: identifier)
        self.playlist = false
        self._name = State(initialValue: "Loading...") // Will be set later by the data fetcher
        self._holder = State(initialValue: .empty)
        self._selectedSeasonNumber = State(initialValue: 0) // Will be set later by the data fetcher
    }
    
    var body: some View {
        @Bindable
        var routerController = routerController
        
        GeometryReader { outerGeometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        switch(holder) {
                        case .success(data: let data):
                            loadedBody(data: data)
                        case .error(error: let error):
                            ExpandedView(geometry: outerGeometry) {
                                ErrorView(error: error)
                            }
                        case .empty, .loading:
                            ExpandedView(geometry: outerGeometry) {
                                ProgressView()
                            }
                        }
                    }
                    .offset(y: -lastOverscroll)
                    .background(
                        GeometryReader { proxy in
                            let position = -proxy.frame(in: .named(SeriesView.scrollableCoordinateSpace)).origin.y
                            Color.clear.onChange(of: position) { _, position in
                                onScroll(scrollOffset: position)
                            }
                        }
                    )
                    .onAppear {
                        routerController.pathHandler = {
                            if(!shouldScrollToHeader) {
                                return false
                            }
                            
                            guard case .success(let data) = holder else {
                                return false
                            }
                            
                            withAnimation {
                                scrollProxy.scrollTo(data.episodable.id, anchor: .center)
                            }
                            return true
                        }
                    }
                }
                .overlay(alignment: .top) {
                    customNavigationBar(outerGeometry: outerGeometry)
                }
                .coordinateSpace(name: SeriesView.scrollableCoordinateSpace)
                .ignoresSafeArea(.all, edges: [.top])
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    customNavigationBarTitle()
                }
                .navigationBarItems(
                    leading: backButton(),
                    trailing: HStack {
                        addToWatchlistButton()
                        shareButton()
                    }
                )
                .sheet(item: $shareText) { shareText in
                    ShareView(sharableLink: shareText)
                }
                .task {
                    if case .empty = holder {
                        await loadData(selectedSeasonIndex: selectedSeasonNumber - 1)
                    }
                }
                .onChange(of: selectedSeasonNumber) { oldValue, newValue in
                    Task {
                        await loadData(selectedSeasonIndex: newValue - 1)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func backButton() -> some View {
        SeriesToolbarButtonView(
            iconName: "chevron.left",
            foregroundColor: !navigationBarTitle.isEmpty,
            backgroundColor: navigationBarTitle.isEmpty ? .material(.thin) : .color(.clear),
            bold: true,
            large: !navigationBarTitle.isEmpty,
            label: "Back",
            labelOpacity: navigationBarOpacity,
            action: {
                dismiss()
            }
        )
        .offset(x: -16)
        .animation(.easeInOut, value: navigationBarTitle)
    }
    
    @ViewBuilder
    private func addToWatchlistButton() -> some View {
        if case .success = holder {
            SeriesToolbarButtonView(
                iconName: "plus",
                foregroundColor: !navigationBarTitle.isEmpty,
                backgroundColor: navigationBarTitle.isEmpty ? .material(.thin) : .material(.thick),
                bold: true,
                large: false,
                action: {
                    if case .success(let data) = holder {
                        routerController.addToWatchlistItem = data.episodable.descriptableEntry
                    }
                }
            )
            .animation(.easeInOut, value: navigationBarTitle)
        }
    }
    
    @ViewBuilder
    private func shareButton() -> some View {
        if case .success(let holder) = holder {
            SeriesToolbarButtonView(
                iconName: "square.and.arrow.up",
                foregroundColor: !navigationBarTitle.isEmpty,
                backgroundColor: navigationBarTitle.isEmpty ? .material(.thin) : .material(.thick),
                bold: true,
                large: true,
                action: {
                    guard let url = URL(string: "https://www.hidive.com/\(playlist ? "playlist" : "season")/\(holder.series?.seasons?[selectedSeasonNumber - 1].id ?? id)") else {
                        return
                    }
                    
                    self.shareText = SharableLink(link: url)
                }
            )
            .animation(.easeInOut, value: navigationBarTitle)
        }
    }
    
    @ViewBuilder
    private func customNavigationBar(outerGeometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Material.thin)
            .frame(height: outerGeometry.safeAreaInsets.top)
            .ignoresSafeArea(.container, edges: .top)
            .opacity(navigationBarOpacity)
    }
    
    @ToolbarContentBuilder
    private func customNavigationBarTitle() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(navigationBarTitle)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .fontWeight(.bold)
                .opacity(navigationBarOpacity)
        }
    }
    
    @ViewBuilder
    private func loadedBody(data: Holder) -> some View {
        NetworkImage(
            thumbnailEntry: data.episodable.wrappedValue.posterUrl!,
            width: .infinity,
            height: thumbnailHeight,
            cornerRadius: 0
        )
        .opacity(thumbnailOpacity)
        .id(data.episodable.id)
        
        Text(data.episodable.wrappedValue.longDescription)
            .frame(maxWidth: .infinity)
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .padding()
            .background(.background.secondary)
            .clipShape(.rect(
                topLeadingRadius: 0,
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 8,
                topTrailingRadius: 0
            ))
        
        if let series = data.series, case .season(let season) = data.episodable {
            seasonSelector(series: series, season: season)
        }else {
            Spacer()
                .frame(height: 12)
        }
        
        let episodes = data.episodable.wrappedValue.episodes?.filter { $0.isValid } ?? []
        ForEach(episodes) { episode in
            episodeCard(data: data, episodes: episodes, episode: episode)
        }
    }
    
    @ViewBuilder
    private func seasonSelector(series: Series, season: Season) -> some View {
        HStack {
            Menu {
                Picker("picker", selection: $selectedSeasonNumber) {
                    ForEach(1...(series.seasonCount ?? 1), id: \.self) { option in
                        Text("Season \(option)")
                    }
                }
                .labelsHidden()
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "chevron.down")
                Spacer()
                    .frame(width: 12)
                Text("Season \(selectedSeasonNumber)")
            }
            .accentColor(colorScheme == .dark ? .white : .black)
            
            Spacer()
            
            DownloadButtonView(downloadEntry: .season(season))
        }
        .frame(height: 60)
        .padding(.horizontal)
        .background(.background.secondary)
        .cornerRadius(8)
        .padding()
        .contextMenu {
            seasonSelectorContextMenu(series: series, season: season)
        }
    }
    
    @ViewBuilder
    private func seasonSelectorContextMenu(series: Series, season: Season) -> some View {
        if let episode = season.episodes?.first {
            Button(
                action: {
                    EpisodePlayer.open(
                        episodable: season,
                        episode: episode,
                        accountController: accountController,
                        animeController: animeController
                    )
                },
                label: {
                    Label("Play", systemImage: "play")
                }
            )
        }
        
        let activeDownload = libraryController.activeDownloads[season.id]
        Button(
            action: {
                Task {
                    if(season.isSaved) {
                        libraryController.removeDownload(episodable: season)
                    }else if let activeDownload = activeDownload {
                        if(activeDownload.paused) {
                            libraryController.resumeDownload(id: season.id)
                        }else {
                            libraryController.pauseDownload(id: season.id)
                        }
                    }else {
                        try await libraryController.addDownload(downloadEntry: .season(season))
                    }
                }
            },
            label: {
                if(season.isSaved) {
                    Label("Delete", systemImage: "trash")
                }else if let activeDownload = activeDownload {
                    if(activeDownload.paused) {
                        Label("Resume download", systemImage: "arrow.down")
                    }else {
                        Label("Pause download", systemImage: "pause")
                    }
                }else {
                    Label("Download", systemImage: "arrow.down")
                }
            }
        )
        
        if let activeDownload = activeDownload, !activeDownload.cancelled, activeDownload.progress < 1 {
            Button(
                action: {
                    Task {
                        libraryController.cancelDownload(episodable: season)
                    }
                },
                label: {
                    Label("Cancel download", systemImage: "stop")
                }
            )
        }
    }
    
    private func onScroll(scrollOffset: CGFloat) {
        let shouldScrollToHeader = scrollOffset > 0
        if(self.shouldScrollToHeader != shouldScrollToHeader) {
            self.shouldScrollToHeader = shouldScrollToHeader
        }
        
        if(scrollOffset < 0) {
            let overscroll = -scrollOffset
            thumbnailHeight += overscroll - lastOverscroll
            lastOverscroll = overscroll
        }else {
            if(scrollOffset <= thumbnailHeight) {
                thumbnailOpacity = 1 - scrollOffset / thumbnailHeight
            }else if(thumbnailOpacity != 0) {
                thumbnailOpacity = 0
            }
            
            let collapseHeight = thumbnailHeight * 0.75
            if(scrollOffset >= collapseHeight && scrollOffset <= thumbnailHeight) {
                // (scroll offset between collapseHeight and thumbnailHeight) : (distance between collapseHeight and thumbnailHeight) = opacity : maxOpacity
                // scrollOffset - collapseHeight : thumbnailHeight - collapseHeight = x : 1
                navigationBarOpacity = (scrollOffset - collapseHeight) / (thumbnailHeight - collapseHeight)
            } else if(scrollOffset < collapseHeight && navigationBarOpacity != 0) {
                navigationBarOpacity = 0
            } else if(scrollOffset > thumbnailHeight && navigationBarOpacity != 1) {
                navigationBarOpacity = 1
            }
            
            if(navigationBarTitle.isEmpty && scrollOffset > collapseHeight) {
                navigationBarTitle = name
            }else if(!navigationBarTitle.isEmpty && scrollOffset < collapseHeight) {
                navigationBarTitle = ""
            }
        }
    }
    
    @ViewBuilder
    private func episodeCard(data: Holder, episodes: [Episode], episode: Episode) -> some View {
        Button(
            action: {
               playEpisode(data: data, episodes: episodes, episode: episode)
            },
            label: {
                VStack(alignment: .leading) {
                    HStack(alignment: .center, spacing: 0) {
                        NetworkImage(
                            thumbnailEntry: episode.thumbnailUrl,
                            width: 175,
                            height: 100,
                            overlay: {
                                EpisodeProgressBar(episode: episode, width: 175, forceProgress: false)
                            }
                        )
                        .layoutPriority(1)
                        
                        Spacer()
                            .frame(width: 12)
                        VStack(alignment: .leading) {
                            Text(episode.title)
                                .font(.system(size: 16))
                                .fontWeight(.bold)
                                .lineLimit(5)
                            Text("\(episode.duration / 60)m")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .layoutPriority(1)
                        
                        Spacer()
                            .frame(minWidth: 12)
                        
                        DownloadButtonView(downloadEntry: .episode(episode))
                            .layoutPriority(1)
                    }
                    
                    if(!playlist) {
                        Spacer()
                            .frame(height: 12)
                        
                        Text(episode.description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(5)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.background.secondary)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom)
            }
        )
        .buttonStyle(.plain)
        .contextMenu {
            episodeCardContextMenu(data: data, episode: episode)
        }
        .disabled(!connectivityController.isConnected && !episode.isSaved)
    }
    
    private func playEpisode(data: Holder, episodes: [Episode], episode: Episode) {
        guard episode.isSaved, let index = episodes.firstIndex(of: episode) else {
            EpisodePlayer.open(
                episodable: data.episodable.wrappedValue,
                episode: episode,
                accountController: accountController,
                animeController: animeController
            )
            return
        }

        let episodes = data.episodable.wrappedValue.episodes
        let nextEpisodes = episodes?.enumerated().compactMap {
            if ($0.offset > index && $0.element.isSaved && $0.element.isValid) {
                return $0.element
            }else {
                return nil
            }
        }
        
        EpisodePlayer.open(
            episodable: data.episodable.wrappedValue,
            episode: episode,
            nextEpisodes: nextEpisodes,
            accountController: accountController,
            animeController: animeController
        )
    }
    
    @ViewBuilder
    private func episodeCardContextMenu(data: Holder, episode: Episode) -> some View {
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
                Label("Play", systemImage: "play")
            }
        )
        
        Button(
            action: {
                Task {
                    if(episode.isSaved) {
                        libraryController.removeAndCancelDownload(episode: episode)
                    }else if let activeDownload = libraryController.activeDownloads[episode.id] {
                        if(activeDownload.paused) {
                            libraryController.resumeDownload(id: episode.id)
                        }else {
                            libraryController.pauseDownload(id: episode.id)
                        }
                    }else {
                        try await libraryController.addDownload(downloadEntry: .episode(episode))
                    }
                }
            },
            label: {
                if(episode.isSaved) {
                    Label("Delete", systemImage: "trash")
                }else if let activeDownload = libraryController.activeDownloads[episode.id] {
                    if(activeDownload.paused) {
                        Label("Resume download", systemImage: "arrow.down")
                    }else {
                        Label("Pause download", systemImage: "pause")
                    }
                }else {
                    Label("Download", systemImage: "arrow.down")
                }
            }
        )
        
        if let activeDownload = libraryController.activeDownloads[episode.id], !activeDownload.cancelled, activeDownload.progress < 1 {
            Button(
                action: {
                    Task {
                        libraryController.removeAndCancelDownload(episode: episode)
                    }
                },
                label: {
                    Label("Cancel download", systemImage: "stop")
                }
            )
        }
    }
    
    private func loadData(selectedSeasonIndex: Int) async {
        do {
            if case .success(let data) = holder, data.download {
                self.holder = .success(Holder(series: data.series, episodable: .season(data.series!.seasons![selectedSeasonIndex]), download: true))
            }else {
                if holder.value == nil {
                    self.holder = .loading
                }
                
                if let id = self.id as? Int {
                    if(playlist) {
                        let playlist = try await animeController.getPlaylist(id: id)
                        self.holder = .success(Holder(series: nil, episodable: .playlist(playlist), download: false))
                    }else {
                        let series = try await animeController.getSeries(id: id)
                        let season = try await animeController.getSeason(id: series.seasons![selectedSeasonIndex].id)
                        self.holder = .success(Holder(series: series, episodable: .season(season), download: false))
                    }
                }else if let id = self.id as? String {
                    guard let episodeIdString = id.split(separator: "#", maxSplits: 2).last, let episodeId = Int(String(episodeIdString)) else {
                        holder = .error(NSError(domain: "Malformed identifier: \(id)", code: -2))
                        return
                    }
                    
                    let episode = try await self.animeController.getEpisode(id: episodeId, includePlayback: false)
                    let season = try await self.animeController.getSeason(id: episode.episodeInformation!.seasonId)
                    let series = try await animeController.getSeries(id: season.parentId)
                    self.name = series.title
                    self.id = series.id
                    self.selectedSeasonNumber = episode.episodeInformation!.seasonNumber
                    self.holder = .success(Holder(series: series, episodable: .season(season), download: false))
                }else {
                    self.holder = .error(NSError(domain: "Unknown identifier type", code: -2))
                }
            }
        }catch let error {
            self.holder = .error(error)
        }
        
        if case .success(let data) = holder {
            let _ = try? await ImageCache.shared.getImageData(url: data.episodable.wrappedValue.posterUrl)
        }
    }
}

private struct Holder {
    let series: Series?
    var episodable: EpisodableEntry
    let download: Bool
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

private struct SharableLink: Identifiable {
    let id: UUID
    let link: URL
    init(link: URL) {
        self.id = UUID()
        self.link = link
    }
}

private struct ShareView: UIViewControllerRepresentable {
    let sharableLink: SharableLink
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareView>) -> UIActivityViewController {
        return UIActivityViewController(activityItems: [sharableLink.link], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareView>) {
        
    }
}
