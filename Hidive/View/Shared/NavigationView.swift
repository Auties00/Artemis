//
//  NavigationView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import AlertToast

struct TabNavigationView<Content>: View where Content : View{
    private var title: String
    private var searchQuery: Binding<String>?
    private let content: () -> Content
    @Environment(AccountController.self)
    private var accountController: AccountController
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    @State
    private var isLoginSheetOpened = false
    @State
    private var isAccountSheetOpened = false
    @State
    private var showProfileError: Bool = false
    @State
    private var routerController: RouterController = RouterController()
    init(title: String, searchQuery: Binding<String>? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.searchQuery = searchQuery
        self.content = content
    }
    
    var body: some View {
        NavigationStack(path: $routerController.path) {
            let result = content()
                .navigationTitle(title)
                .navigationBarLargeTitleItems(trailing: ProfileButtonView(action: handleSheet))
                .navigationDestination(for: NestedPageType.self, destination: handleDestination)
            if let searchQuery = searchQuery {
                result.searchable(text: searchQuery, placement: .navigationBarDrawer(displayMode: .always))
            }else {
              result
            }
        }
        .sheet(isPresented: $isLoginSheetOpened, content: {
            LoginSheet() {
                isLoginSheetOpened = false
            }
        })
        .sheet(isPresented: $isAccountSheetOpened, content: {
            if case .success(let profile) = accountController.profile, let profile = profile {
                AccountSheet(profile: profile) {
                    isAccountSheetOpened = false
                }
            }
        })
        .toast(isPresenting: $showProfileError) {
            let reason = accountController.profile.error?.localizedDescription ?? "Unknown error"
            return AlertToast(type: .error(Color.red), title: "Profile Error", subTitle: reason)
        }
        .environment(routerController)
    }
    
    private func handleSheet(loggedIn: Bool) {
        if case .error = accountController.profile {
            self.showProfileError = true
        } else if(loggedIn) {
            isAccountSheetOpened = true
        }else {
            isLoginSheetOpened = true
        }
    }
    
    @ViewBuilder
    private func handleDestination(destination: NestedPageType) -> some View {
        switch(destination) {
        case .schedule(let identifier):
            SeriesView(
                identifier: identifier
            )
        case .search(let searchEntry):
            let _ = print("\(searchEntry.id) - \(searchEntry.type)")
            SeriesView(
                id: searchEntry.id,
                name: searchEntry.name,
                playlist: searchEntry.type == "VOD_PLAYLIST"
            )
        case .home(let bucketEntry, let lastWatchedEpisode):
            let playlist = if case .playlist = bucketEntry {
                true
            } else {
                false
            }
            SeriesView(
                id: bucketEntry.parentId,
                name: bucketEntry.parentTitle,
                playlist: playlist,
                selectedSeasonNumber: lastWatchedEpisode?.episodeInformation?.seasonNumber
            )
        case .library(let libraryPageType):
            switch(libraryPageType) {
            case .downloads:
                DownloadsView()
            case .download(let download):
                SeriesView(downloadedEntry: download)
            case .watchlists:
                WatchlistsView()
            case .watchlist(let watchlist):
                WatchlistView(unattributedWatchlist: watchlist)
            case .history:
                WatchHistoryView()
            }
        }
    }
}

private extension View {
    func navigationBarLargeTitleItems<L>(trailing: L) -> some View where L : View {
        overlay(NavigationBarLargeTitleItems(trailingItems: trailing)
            .frame(width: 0, height: 0))
    }
}

private struct NavigationBarLargeTitleItems<L : View>: UIViewControllerRepresentable {
    typealias UIViewControllerType = NavigationBarLargeTitleItemsController
    
    private let trailingItems: L
    init(trailingItems: L) {
        self.trailingItems = trailingItems
    }
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        NavigationBarLargeTitleItemsController(trailingItems: trailingItems)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    
    }
    
    class NavigationBarLargeTitleItemsController: UIViewController {
        private let trailingItems: L
        init(trailingItems: L) {
            self.trailingItems = trailingItems
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
           fatalError("Not implemented")
        }
        
        override func viewWillAppear(_ animated: Bool) {
            guard let navigationBar = self.navigationController?.navigationBar else {
                return
            }
            
            guard let subview = navigationBar.largeTitle else {
                return
            }
            
            let controller = UIHostingController(rootView: trailingItems)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            controller.view.backgroundColor = UIColor.clear
            subview.addSubview(controller.view)
            
            NSLayoutConstraint.activate([
                controller.view.trailingAnchor.constraint(equalTo: subview.trailingAnchor),
                controller.view.bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: -8)
            ])
        }
        
        override func viewWillDisappear(_: Bool) {
            guard let navigationBar = navigationController?.navigationBar else {
                return
            }
            
            guard let subview = navigationBar.largeTitle else {
                return
            }
            
            subview.alpha = 0
        }
    }
}

private extension UINavigationBar {
    var largeTitle: UIView? {
        self.subviews.first(where: { String(describing: $0.self).contains("_UINavigationBarLargeTitleView") })
    }
}
