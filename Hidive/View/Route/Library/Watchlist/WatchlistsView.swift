//
//  WatchlistsView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 27/07/24.
//

import SwiftUI

struct WatchlistsView: View {
    @State
    private var createWatchlistDialog: Bool = false
    
    @State
    private var editWatchlistDialog: Bool = false
    
    @State
    private var editWatchlistItem: Watchlist? = nil
    
    @State
    private var watchlistName: String = ""
    
    @State
    private var searchText: String = ""
    
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    var body: some View {
        GeometryReader { geometry in
            List {
                if(!accountController.isLoggedIn()) {
                    ExpandedView(geometry: geometry) {
                        ContentUnavailableView(
                            "No watchlists",
                            systemImage: "rectangle.stack.fill",
                            description: Text("Only registered users can view their watchlists")
                        )
                    }
                }else {
                    switch(libraryController.watchlists) {
                    case .success(let watchlists):
                        loadedBody(geometry: geometry, watchlists: watchlists)
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
            }
            .environment(\.defaultMinListHeaderHeight, 12)
            .listRowSpacing(12)
            .alert("New watchlist", isPresented: $createWatchlistDialog, actions: newWatchlistDialog)
            .alert("Rename", isPresented: $editWatchlistDialog, actions: renameWatchlistDialog)
            .navigationTitle("Watchlists")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationBarItems(trailing: newWatchlistButton())
        }
        .refreshable {
            if(accountController.profile.value == nil) {
                await accountController.login()
            }
            
            await libraryController.loadWatchlists()
        }
    }
    
    @ViewBuilder
    private func loadedBody(geometry: GeometryProxy, watchlists: Watchlists) -> some View {
        if(watchlists.data.isEmpty) {
            ExpandedView(geometry: geometry) {
                ContentUnavailableView(
                    "No watchlists",
                    systemImage: "rectangle.stack.fill",
                    description: Text("Your watchlists will be displayed here")
                )
            }
        }else {
            let filteredWatchlists = searchText.isEmpty ? watchlists.data : watchlists.data.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
            if(filteredWatchlists.isEmpty) {
                if(watchlists.moreDataAvailable) {
                    ExpandedView(geometry: geometry) {
                        LoadingView()
                    }.task {
                        await libraryController.loadWatchlists(lastSeen: watchlists.lastSeen)
                    }
                }else {
                    ExpandedView(geometry: geometry) {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }else {
                Section(header: Spacer(minLength: 0).listRowInsets(EdgeInsets())) {
                    ForEach(filteredWatchlists) { watchlist in
                        NavigationLink(value: NestedPageType.library(.watchlist(watchlist))) {
                            WatchlistCardView(watchlist: watchlist).contextMenu {
                                watchlistCardContextMenu(watchlists: watchlists, watchlist: watchlist)
                            }
                        }
                    }
                    .onDelete {
                        var removedWatchlists: [Watchlist] = []
                        for index in $0 {
                            let removed = watchlists.data.remove(at: index)
                            removedWatchlists.append(removed)
                        }
                        
                        onDelete(toRemove: removedWatchlists)
                    }
                    
                    if(watchlists.moreDataAvailable) {
                        LoadingMoreView {
                            await libraryController.loadWatchlists(lastSeen: watchlists.lastSeen)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func watchlistCardContextMenu(watchlists: Watchlists, watchlist: Watchlist) -> some View {
        Button {
            routerController.path.append(NestedPageType.library(.watchlist(watchlist)))
        } label: {
            Label("Open", systemImage: "arrow.forward")
        }
        
        Button {
            self.watchlistName = watchlist.name
            self.editWatchlistDialog = true
            self.editWatchlistItem = watchlist
        } label: {
            Label("Rename", systemImage: "pencil")
        }
        
        Button {
            guard let index = watchlists.data.firstIndex(of: watchlist) else {
                return
            }
            
            watchlists.data.remove(at: index)
            onDelete(toRemove: [watchlist])
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private func newWatchlistButton() -> some View {
        Button(
            action: {
                createWatchlistDialog.toggle()
            },
            label: {
                Image(systemName: "plus")
            }
        )
    }
    
    @ViewBuilder
    private func newWatchlistDialog() -> some View {
        TextField("Name", text: $watchlistName)
        Button("Create") {
            Task {
                do {
                    let name = watchlistName
                    watchlistName = ""
                    try await libraryController.createWatchlist(name: name)
                }catch let error {
                    print("Error: \(error)")
                }
            }
        }
        Button("Cancel", role: .cancel) {
            watchlistName = ""
        }
    }
    
    @ViewBuilder
    private func renameWatchlistDialog() -> some View {
        TextField("Name", text: $watchlistName)
        Button("Rename") {
            guard let watchlist = editWatchlistItem else {
                return
            }
            
            Task {
                do {
                    let name = watchlistName
                    watchlistName = ""
                    try await libraryController.renameWatchlist(watchlist: watchlist, name: name)
                }catch let error {
                    print("Error: \(error)")
                }
            }
        }
        Button("Cancel", role: .cancel) {
            watchlistName = ""
        }
    }
    
    private func onDelete(toRemove: [Watchlist]) {
        Task {
            for watchlist in toRemove {
                do {
                    try await libraryController.deleteWatchlist(watchlist: watchlist)
                }catch let error {
                    print("Error: \(error)")
                }
            }
        }
    }
}
