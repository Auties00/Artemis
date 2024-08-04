//
//  HeroCarouselView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 18/07/24.
//

import SwiftUI
import ACarousel

struct HeroCarouselView: View {
    private let heroes: [Hero]
    init(heroes: [Hero]) {
        self.heroes = heroes
    }
    
    var body: some View {
        ACarousel(heroes, spacing: 0, headspace: 0) { hero in
            HeroCardView(hero: hero)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, minHeight: 450, maxHeight: 450)
    }
}

private struct HeroCardView: View {
    private let hero: Hero
    init(hero: Hero) {
        self.hero = hero
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                NetworkImage(url: hero.link!.event!.coverUrl!)
                    .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                
                Spacer()
                    .frame(height: 8)
                
                Text(hero.link!.event!.title!)
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                
                buildDescription()
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                    .frame(height: 8)
                
                Text(hero.link!.event!.description!)
                    .font(.system(size: 16))
            }
            
            Spacer()
            
            Button(
                action: {},
                label: {
                    HStack(alignment: .center) {
                        Image(systemName: "play.fill")
                        Text("WATCH NOW")
                    }.frame(maxWidth: .infinity, maxHeight: 36)
                }
            ).buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private func buildDescription() -> some View {
        switch(hero.link!.event!) {
        case .season(season: let season):
            let seasonNumber = season.seasonNumber ?? 1
            let contentRating = if let rating = season.series?.contentRating?.rating {
                " | \(rating)"
            } else {
                ""
            }
            Text("Season \(seasonNumber) | \(season.episodeCount) episode\(season.episodeCount > 1 ? "s" : "")\(contentRating)")
        case .series(series: let series):
            let seasons = series.seasonCount ?? -1
            let contentRating = if let rating = series.contentRating?.rating {
                " | \(rating)"
            } else {
                ""
            }
            Text("\(seasons) season\(seasons > 1 ? "s" : "")\(contentRating)")
        case .episode(episode: let episode):
            Text(episode.description)
        case .playlist:
            fatalError("Not implemented")
        }
    }
}
