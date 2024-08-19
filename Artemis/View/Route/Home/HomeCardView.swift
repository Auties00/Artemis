//
//  HeroCarouselView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 04/08/24.
//

import SwiftUI
import ACarousel
import AlertToast

struct HeroHeaderView: View {
    private let heroes: [Hero]
    init(heroes: [Hero]) {
        self.heroes = heroes
    }
    
    var body: some View {
        TabView {
            ForEach(heroes) { hero in
                NetworkImage(
                    thumbnailEntry: hero.imageUrl,
                    width: .infinity,
                    height: 800,
                    cornerRadius: 0
                )
                .overlay(alignment: .bottom) {
                    if case .url(let url) = hero.titleImage {
                        AsyncImage(url: URL(string: url)!)  { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300)
                                .padding(.bottom, 60)
                        } placeholder: {
                            
                        }
                    }
                }
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(maxWidth: .infinity, minHeight: 800)
        .padding(.bottom)
    }
}

struct HeroCarouselView: View {
    private let heroes: [Hero]
    init(heroes: [Hero]) {
        self.heroes = heroes
    }
    
    var body: some View {
        ACarousel(heroes) { hero in
            HeroCardView(hero: hero)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, minHeight: 475)
    }
}

struct HeroCardView: View {
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
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                NetworkImage(
                    thumbnailEntry: hero.link.event.coverUrl,
                    width: .infinity,
                    height: 200
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
        .background(.background.secondary)
        .onTapGesture {
            routerController.path.append(NestedPageType.home(hero.link.event, lastWatchedEpisode: hero.lastWatchedEpisode))
        }
        .contextMenu {
            Button {
                watchNow(hero: hero)
            } label: {
                Label(hero.lastWatchedEpisode != nil ? "Continue Watching" : "Start Watching", systemImage: "play")
            }
            
            Button {
                routerController.path.append(NestedPageType.home(hero.link.event, lastWatchedEpisode: hero.lastWatchedEpisode))
            } label: {
                Label("Go to Anime", systemImage: "info.circle")
            }
            
            Button {
                routerController.addToWatchlistItem = hero.link.event
            } label: {
                Label("Add to Watchlist", systemImage: "list.star")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        let result = VStack(alignment: .leading, spacing: 0) {
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
                                        accountController: accountController,
                                        animeController: animeController
                                    )
                                },
                                label: {
                                    label
                                }
                            )
                            .buttonStyle(.plain)
                        }else {
                            NavigationLink(value: NestedPageType.home(contentEntry)) {
                                label
                            }
                            .buttonStyle(.plain)
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
        .background(Color.backgroundColor)
        .cornerRadius(8)
        .padding(.bottom)
        
        if(UIDevice.current.userInterfaceIdiom == .pad) {
            result
        }else {
            result.padding(.horizontal)
        }
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
        .background(Color.backgroundColor)
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
        
        if case .episode = contentEntry {
            
        }else {
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
            
            routerController.path.append(NestedPageType.home(.season(season)))
        } else {
            routerController.path.append(NestedPageType.home(contentEntry))
        }
    }
}

private extension View {
    func watchNow(accountController: AccountController, animeController: AnimeController, bucketEntry: DescriptableEntry) async throws {
        switch(bucketEntry) {
        case .episode(let episode):
            await EpisodePlayer.open(
                episodable: nil,
                episode: episode,
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

// Can't use .background.secondary or it will be stacked, making the colour wrong
private extension Color {
    static let backgroundColor: Color = Color(UIColor.secondarySystemGroupedBackground)
}
