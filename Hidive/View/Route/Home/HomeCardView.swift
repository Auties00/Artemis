//
//  HeroCarouselView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 04/08/24.
//

import SwiftUI
import ACarousel
import AlertToast

struct HeroCarouselView: View {
    private let heroes: [Hero]
    init(heroes: [Hero]) {
        self.heroes = heroes
    }
    
    var body: some View {
        ACarousel(heroes, isWrap: true) { hero in
            HeroCardView(hero: hero)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, minHeight: 475)
    }
}

private struct HeroCardView: View {
    private let hero: Hero
    @State
    private var addToWatchlistItem: DescriptableEntry?
    @State
    private var error: Bool = false
    @State
    private var addedItemToWatchlist: Bool = false
    @Environment(AccountController.self)
    private var accountController: AccountController
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    @Environment(RouterController.self)
    private var routerController: RouterController
    init(hero: Hero) {
        self.hero = hero
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                NetworkImage(thumbnailEntry: hero.link.event.coverUrl)
                    .frame(maxWidth: .infinity, minHeight: 200)
                
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
                if case .season(let season) = hero.link.event {
                    self.addToWatchlistItem = .series(season.series!)
                }else {
                    self.addToWatchlistItem = hero.link.event
                }
            } label: {
                Label("Add to Watchlist", systemImage: "list.star")
            }
        }
        .sheet(item: $addToWatchlistItem) { item in
            AddToWatchlistSheet(item: item) { addedItemToWatchlist in
                addToWatchlistItem = nil
                self.addedItemToWatchlist = addedItemToWatchlist
            }
        }
        .toast(isPresenting: $addedItemToWatchlist) {
            AlertToast(type: .complete(Color.green), title: "Added item to watchlist", subTitle: "Tap to dismiss")
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
    private let bucket: Bucket
    @State
    private var addToWatchlistItem: DescriptableEntry?
    @State
    private var error: Bool = false
    @State
    private var addedItemToWatchlist: Bool = false
    @Environment(AccountController.self)
    private var accountController: AccountController
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    @Environment(RouterController.self)
    private var routerController: RouterController
    init(bucket: Bucket) {
        self.bucket = bucket
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(toBucketTitle(input: bucket.name))
                .font(.system(size: 24))
                .fontWeight(.bold)
            
            Spacer()
                .frame(height: 6)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(bucket.contentList) { contentEntry in
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
                                    bucketEntryCard(contentEntry: contentEntry)
                                }
                            )
                            .frame(width: 250)
                            .buttonStyle(.plain)
                        }else {
                            NavigationLink(value: NestedPageType.home(contentEntry)) {
                                bucketEntryCard(contentEntry: contentEntry)
                            }
                            .frame(width: 250)
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .padding(.bottom)
        .sheet(item: $addToWatchlistItem) { item in
            AddToWatchlistSheet(item: item) { addedItemToWatchlist in
                addToWatchlistItem = nil
                self.addedItemToWatchlist = addedItemToWatchlist
            }
        }
        .toast(isPresenting: $addedItemToWatchlist) {
            AlertToast(type: .complete(Color.green), title: "Added item to watchlist", subTitle: "Tap to dismiss")
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
    
    @ViewBuilder
    private func bucketEntryCard(contentEntry: DescriptableEntry) -> some View {
        VStack(alignment: .leading) {
            if case .episode(let episode) = contentEntry {
                EpisodeThumbnail(
                    episode: episode,
                    width: 250,
                    height: 150,
                    fill: true,
                    forceProgress: true
                )
            }else {
                NetworkImage(thumbnailEntry: contentEntry.coverUrl)
                    .frame(width: 250, height: 150)
            }
            
            Text(contentEntry.parentTitle)
                .font(.system(size: 16))
                .fontWeight(.bold)
                .lineLimit(1)
            
            description(bucketEntry: contentEntry)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
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
                if case .season(let season) = contentEntry {
                    self.addToWatchlistItem = .series(season.series!)
                }else {
                    self.addToWatchlistItem = contentEntry
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
