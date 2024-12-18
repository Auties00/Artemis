//
//  HeroCarouselView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 04/08/24.
//

import SwiftUI
import AlertToast

struct HeroCarouselView: View {
    @State
    private var items: [HeroItem]
    private let heroes: [Hero]
    init(heroes: [Hero]) {
        self.heroes = heroes
        var items: [HeroItem] = []
        for hero in heroes {
            items.append(HeroItem(hero: hero))
        }
        self._items = State(initialValue: items)
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(items) { item in
                    card(item.hero)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.never)
        .contentMargins(.leading, 16)
        .contentMargins(.trailing, 40)
        .frame(height: UIScreen.main.bounds.size.height / 1.9621)
        .padding(.top)
    }
    
    @ViewBuilder
    private func card(_ hero: Hero) -> some View {
        let result = HeroCardView(hero: hero)
           .containerRelativeFrame(.horizontal)
           .scrollTransition { content, phase in
               content
                   .opacity(phase.isIdentity ? 1.0 : 0.95)
                   .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
           }
        if(hero == heroes.last) {
            result.onAppear {
                for hero in heroes {
                    items.append(HeroItem(hero: hero))
                }
            }
        }else {
            result
        }
    }
}

fileprivate struct HeroItem: Identifiable {
    let id: UUID
    let hero: Hero
    init(hero: Hero) {
        self.id = UUID()
        self.hero = hero
    }
    
    func copy() -> HeroItem {
        return HeroItem(hero: hero)
    }
}

fileprivate struct HeroCardView: View {
    @State
    private var error: Bool = false
    
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    private let hero: Hero
    init(hero: Hero) {
        self.hero = hero
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                NetworkImage(
                    thumbnailEntry: hero.link.event.coverUrl,
                    width: .infinity,
                    height: 175
                )
                
                Spacer()
                    .frame(height: 8)
                
                Text(hero.link.event.title)
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                
                description(bucketEntry: hero.link.event)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                    .frame(height: 8)
                
                Text(hero.link.event.description)
                    .font(.system(size: 16))
            }
            
            Spacer()
            
            Button(
                action: {
                    watchNow(hero: hero)
                },
                label: {
                    HStack(alignment: .center) {
                        Image(systemName: "play.fill")
                        if let lastWatchedEpisode = hero.lastWatchedEpisode {
                            let seasonNumber = lastWatchedEpisode.episodeInformation?.seasonNumber ?? 1
                            let episodeNumber = String(lastWatchedEpisode.title.split(separator: " ", maxSplits: 2)[0])
                            Text("CONTINUE S\(seasonNumber) \(episodeNumber)")
                        }else {
                            Text("WATCH NOW")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 36)
                }
            )
            .buttonStyle(.borderedProminent)
            .accentColor(.accentColor)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .onTapGesture {
            routerController.path.append(NestedPageType.series(hero.link.event, lastWatchedEpisode: hero.lastWatchedEpisode))
        }
        .contextMenu {
            Button {
                watchNow(hero: hero)
            } label: {
                Label(hero.lastWatchedEpisode != nil ? "Continue Watching" : "Start Watching", systemImage: "play")
            }
            
            Button {
                routerController.path.append(NestedPageType.series(hero.link.event, lastWatchedEpisode: hero.lastWatchedEpisode))
            } label: {
                Label("Go to Anime", systemImage: "info.circle")
            }
            
            Button {
                routerController.addToWatchlistItem = hero.link.event
            } label: {
                Label("Add to Watchlist", systemImage: "list.star")
            }
        }
        .alert(
            "Player error",
            isPresented: $error,
            actions: {},
            message: {
                Text("Cannot open player")
            }
        )
    }
    
    private func watchNow(hero: Hero) {
        if let lastWatchedEpisode = hero.lastWatchedEpisode {
            EpisodePlayer.open(
                episodable: nil,
                episode: lastWatchedEpisode,
                routerController: routerController,
                accountController: accountController,
                animeController: animeController
            ) {
                hero.lastWatchedEpisode = $0
            }
            return
        }
        
        Task {
            do {
                try await watchNow(
                    routerController: routerController,
                    accountController: accountController,
                    animeController: animeController,
                    bucketEntry: hero.link.event
                )
            }catch {
                self.error = true
            }
        }
    }
}

struct BucketSectionView: View {
    @State
    private var error: Bool = false
    
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme
    
    private let bucket: Bucket
    init(bucket: Bucket) {
        self.bucket = bucket
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(toBucketTitle(input: bucket.name))
                .font(.system(size: 20))
                .fontWeight(.bold)
                .padding(.top, 12)
                .padding(.leading, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(bucket.contentList) { contentEntry in
                        let label = bucketEntryCard(contentEntry: contentEntry)
                        if case .episode(let episode) = contentEntry {
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
                                    label
                                }
                            )
                            .buttonStyle(.plain)
                            .tag(contentEntry)
                        }else {
                            NavigationLink(value: NestedPageType.series(contentEntry)) {
                                label
                            }
                            .buttonStyle(.plain)
                            .tag(contentEntry)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .alert(
            "Player error",
            isPresented: $error,
            actions: {},
            message: {
                Text("Cannot open player")
            }
        )
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .padding()
    }
    
    
    @ViewBuilder
    private func bucketEntryCard(contentEntry: DescriptableEntry) -> some View {
        VStack(alignment: .leading) {
            NetworkImage(
                thumbnailEntry: contentEntry.coverUrl,
                width: 250,
                height: 150,
                overlay: {
                    if case .episode(let episode) = contentEntry {
                        EpisodeProgressBar(episode: episode, width: 250, forceProgress: true)
                    }
                }
            )
            
            Text(contentEntry.parentTitle)
                .font(.system(size: 16))
                .fontWeight(.bold)
                .lineLimit(1)
            
            description(bucketEntry: contentEntry)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 250)
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .contextMenu {
            bucketEntryContexMenu(contentEntry: contentEntry)
        }
    }
    
    @ViewBuilder
    private func bucketEntryContexMenu(contentEntry: DescriptableEntry) -> some View {
        Button {
            watchNow(contentEntry: contentEntry)
        } label: {
            if case .episode = contentEntry {
                Label("Continue Watching", systemImage: "play")
            }else {
                Label("Start Watching", systemImage: "play")
            }
        }
        
        Button {
            goToAnime(contentEntry: contentEntry)
        } label: {
            Label("Go to Anime", systemImage: "info.circle")
        }
        
        if(!isEpisode(contentEntry)) {
            Button {
                routerController.addToWatchlistItem = if case .season(let season) = contentEntry {
                    .series(season.series!)
                }else {
                    contentEntry
                }
            } label: {
                Label("Add to Watchlist", systemImage: "list.star")
            }
        }
    }
    
    private func isEpisode(_ contentEntry: DescriptableEntry) -> Bool {
        if case .episode = contentEntry {
            return true
        }else {
            return false
        }
    }
    
    private func toBucketTitle(input: String?) -> String {
        guard let input = input else {
            return ""
        }
        
        return input.split(separator: " ")
            .map { $0.lowercased().capitalized }
            .joined(separator: " ")
    }
    
    private func watchNow(contentEntry: DescriptableEntry) {
        Task {
            do {
                try await watchNow(
                    routerController: routerController,
                    accountController: accountController,
                    animeController: animeController,
                    bucketEntry: contentEntry
                )
            }catch {
                self.error = true
            }
        }
    }
    
    private func goToAnime(contentEntry: DescriptableEntry) {
        if case .episode(let episode) = contentEntry {
            guard let season = episode.episodeInformation?.season else {
                return
            }
            
            routerController.path.append(NestedPageType.series(.season(season), lastWatchedEpisode: episode))
        } else {
            routerController.path.append(NestedPageType.series(contentEntry))
        }
    }
}

fileprivate extension View {
    func watchNow(routerController: RouterController, accountController: AccountController, animeController: AnimeController, bucketEntry: DescriptableEntry) async throws {
        switch(bucketEntry) {
        case .episode(let episode):
            await EpisodePlayer.open(
                episodable: nil,
                episode: episode,
                routerController: routerController,
                accountController: accountController,
                animeController: animeController
            )
        case .series(let series):
            let series = try await animeController.getSeries(id: series.id)
            guard let seasonId = series.seasons?.first?.id else {
                return
            }
            
            let season = try await animeController.getSeason(id: seasonId)
            guard let episode = season.episodes?.first else {
                return
            }
            
            await EpisodePlayer.open(
                episodable: season,
                episode: episode,
                routerController: routerController,
                accountController: accountController,
                animeController: animeController
            )
        case .season(let season):
            let season = try await animeController.getSeason(id: season.id)
            guard let episode = season.episodes?.first else {
                return
            }
            
            await EpisodePlayer.open(
                episodable: season,
                episode: episode,
                routerController: routerController,
                accountController: accountController,
                animeController: animeController
            )
        case .playlist(let playlist):
            let playlist = try await animeController.getPlaylist(id: playlist.id)
            guard let episode = playlist.episodes?.first else {
                return
            }
            
            await EpisodePlayer.open(
                episodable: playlist,
                episode: episode,
                routerController: routerController,
                accountController: accountController,
                animeController: animeController
            )
        }
    }
    
    @ViewBuilder
    func description(bucketEntry: DescriptableEntry) -> some View {
        switch(bucketEntry) {
        case .season(season: let season):
            let seasonNumber = season.seasonNumber
            let contentRating = if let rating = season.series?.rating?.rating {
                " | \(rating)"
            } else {
                ""
            }
            Text("Season \(seasonNumber) | \(season.episodeCount) episode\(season.episodeCount != 1 ? "s" : "")\(contentRating)")
        case .series(series: let series):
            let contentRating = if let rating = series.rating?.rating {
                " | \(rating)"
            } else {
                ""
            }
            
            if let seasons = series.seasonCount {
                Text("\(seasons) season\(seasons != 1 ? "s" : "")\(contentRating)")
            }else {
                Text(contentRating)
            }
        case .episode(episode: let episode):
            Text(episode.title)
        case .playlist(let playlist):
            Text("\(playlist.episodesCount) video\(playlist.episodesCount != 1 ? "s" : "")")
        }
    }
}

// Can't use .background.secondary or it will be stacked, making the color wrong
fileprivate extension Color {
    static let backgroundColor: Color = Color(UIColor.secondarySystemGroupedBackground)
}
