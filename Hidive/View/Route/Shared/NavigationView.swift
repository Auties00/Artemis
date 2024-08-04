//
//  NavigationView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import SwiftUIIntrospect

struct TabNavigationView<Content>: View where Content : View{
    private var title: String
    private var searchQuery: Binding<String>?
    private let content: () -> Content
    @EnvironmentObject
    private var accountController: AccountController
    @State
    private var navigationPath: [PageType] = []
    @State
    private var attachedActionView: Bool = false
    init(title: String, searchQuery: Binding<String>? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.searchQuery = searchQuery
        self.content = content
    }
    
    var body: some View {
        let result = NavigationStack(path: $navigationPath) {
            content().navigationTitle(title).navigationDestination(for: PageType.self) { destination in
                switch(destination) {
                case .scheduleEntry(data: let scheduleEntry):
                    SeriesView(
                        id: scheduleEntry.season.id,
                        idType: "SEASON",
                        thumbnail: scheduleEntry.season.coverUrl,
                        name: scheduleEntry.season.title,
                        description: scheduleEntry.season.description
                    )
                case .episode(data: let episode):
                    EpisodePlayerView(
                        episodeName: episode.title,
                        episodeId: episode.id
                    )
                case .search(data: let searchEntry):
                    SeriesView(
                        id: searchEntry.id,
                        idType: "SERIES",
                        thumbnail: searchEntry.coverUrl,
                        name: searchEntry.name,
                        description: searchEntry.description
                    )
                case .season(data: let bucketEntry):
                    switch(bucketEntry) {
                    case .episode:
                        EpisodePlayerView(
                            episodeName: bucketEntry.title!,
                            episodeId: bucketEntry.id!
                        )
                    case .season:
                        SeriesView(
                            id: bucketEntry.id!,
                            idType: "SEASON",
                            thumbnail: bucketEntry.coverUrl!,
                            name: bucketEntry.title!,
                            description: bucketEntry.description!
                        )
                    case .series:
                        SeriesView(
                            id: bucketEntry.id!,
                            idType: "SERIES",
                            thumbnail: bucketEntry.coverUrl!,
                            name: bucketEntry.title!,
                            description: bucketEntry.description!
                        )
                    case .playlist:
                        fatalError("Not implemented")
                    }
                case .library(data: let libraryPageType):
                    switch(libraryPageType) {
                    case .downloads:
                        DownloadsView()
                    case .favourites:
                        FavouritesView()
                    case .history:
                        WatchHistoryView()
                    }
                }
            }
        }.introspect(.navigationStack, on: .iOS(.v16, .v17, .v18), scope: .receiver) { navController in
            let bar = navController.navigationBar
            
            let hosting = UIHostingController(rootView: ProfileButtonView(accountController: accountController))
            
            guard let hostingView = hosting.view else {
                return
            }
            guard let parent = bar.subviews.first(where: \.clipsToBounds) else {
                return
            }
            
            if(attachedActionView) {
                parent.subviews.last?.removeFromSuperview()
            }
            
            if(!navigationPath.isEmpty) {
                return
            }
            
            parent.addSubview(hostingView)
            self.attachedActionView = true
            hostingView.backgroundColor = .clear
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                hostingView.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
                hostingView.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -8)
            ])
        }
        
        
        if(searchQuery == nil) {
            result
        }else {
            result.searchable(text: searchQuery!, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}


