//
//  NavigationView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import AlertToast

struct TabNavigationView<Content>: View where Content : View{
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    @State
    private var isLoginSheetOpened = false
    
    @State
    private var isAccountSheetOpened = false
    
    @State
    private var showProfileError: Bool = false
    
    @State
    private var addedItemToWatchlist: Bool = false
    
    private let title: String
    private let content: () -> Content
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        @Bindable
        var routerController = routerController
        
        NavigationStack(path: $routerController.path) {
            let result = content()
                .navigationTitle(title)
                .navigationDestination(for: NestedPageType.self, destination: handleDestination)
            if(UIDevice.current.userInterfaceIdiom == .pad) {
                result
            }else {
                result
                    .navigationBarLargeTitleItems(trailing: ProfileButtonView(action: handleSheet))
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
        .sheet(item: $routerController.addToWatchlistItem) { item in
            AddToWatchlistSheet(item: item) { addedItemToWatchlist in
                routerController.addToWatchlistItem = nil
                self.addedItemToWatchlist = addedItemToWatchlist
            }
        }
        .toast(isPresenting: $showProfileError) {
            let reason = accountController.profile.error?.localizedDescription ?? "Unknown error"
            return AlertToast(type: .error(Color.red), title: "Profile Error", subTitle: reason)
        }
        .toast(isPresenting: $addedItemToWatchlist) {
            AlertToast(type: .complete(Color.green), title: "Added item to watchlist", subTitle: "Tap to dismiss")
        }
    }
    
    private func handleSheet(loggedIn: Bool) {
        if(loggedIn && accountController.profile.error != nil) {
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
        case .scheduleEntry(let identifier):
            SeriesView(
                identifier: identifier
            )
        case .searchResult(let searchEntry):
            let _ = hideKeyboard() // Dismiss keyboard from search 
            SeriesView(
                id: searchEntry.id,
                name: searchEntry.name,
                playlist: searchEntry.type == "VOD_PLAYLIST"
            )
        case .series(let bucketEntry, let lastWatchedEpisode):
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
        case .librarySection(let libraryPageType):
            switch(libraryPageType) {
            case .downloads:
                DownloadsView()
            case .download(let download):
                SeriesView(downloadedEntry: download)
            case .watchlists:
                WatchlistsView()
            case .watchlist(let watchlist):
                WatchlistView(watchlist: watchlist)
            case .history:
                WatchHistoryView()
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private extension View {
    func navigationBarLargeTitleItems<L>(trailing: L) -> some View where L : View {
        overlay(NavigationBarLargeTitleItems(trailingItems: trailing)
            .frame(width: 0, height: 0))
    }
}

private extension UINavigationBar {
    var largeTitle: UIView? {
        self.subviews.first(where: { String(describing: $0.self).contains("_UINavigationBarLargeTitleView") })
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
        private var attachedView: UIView?
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
            self.attachedView?.removeFromSuperview()
            self.attachedView = nil
            
            guard let nextAttachedView = controller.view else {
                return
            }
            
            subview.addSubview(nextAttachedView)
            self.attachedView = nextAttachedView
            
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

extension NavigationLink where Label == EmptyView, Destination == EmptyView {
    static var empty: NavigationLink {
        self.init(destination: EmptyView(), label: { EmptyView() })
    }
 }
