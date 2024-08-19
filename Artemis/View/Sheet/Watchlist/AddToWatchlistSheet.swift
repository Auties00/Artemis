//
//  AddToWatchlistSheet.swift
//   Artemis
//
//  Created by Alessandro Autiero on 01/08/24.
//

import SwiftUI
import AlertToast

struct AddToWatchlistSheet: View {
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme
    
    private let item: DescriptableEntry
    
    @State
    private var searchText: String = ""
    
    @State
    private var createWatchlistDialog: Bool = false
    
    @State
    private var watchlistName: String = ""
    
    @State
    private var loadingToast: Bool = false
    
    @State
    private var loadingTitle: String?
    
    @State
    private var errorToast: Bool = false
    
    @State
    private var errorTitle: String?
    
    @State
    private var error: Error?
    
    private let onDismiss: (Bool) -> Void
    init(item: DescriptableEntry, onDismiss: @escaping (Bool) -> Void) {
        self.item = item
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                List {
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
            .environment(\.defaultMinListHeaderHeight, 0)
            .listRowSpacing(12)
            .navigationBarTitle("Add to Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .ignoresSafeArea(.keyboard)
            .alert("New watchlist", isPresented: $createWatchlistDialog, actions: newWatchlistDialog)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(
                        action: {
                            createWatchlistDialog.toggle()
                        },
                        label: {
                            Text("Create")
                        }
                    )
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ExitButtonView() {
                        onDismiss(false)
                    }
                }
            })
            .toast(isPresenting: $loadingToast) {
                AlertToast(type: .loading, title: loadingTitle)
            }
            .toast(isPresenting: $errorToast) {
                if let requestError = error as? RequestError, case .invalidResponseStatusCode(let statusCode, _) = requestError, statusCode == 409 {
                    AlertToast(type: .error(Color.red), title: errorTitle, subTitle: "Duplicated item")
                }else {
                    AlertToast(type: .error(Color.red), title: errorTitle, subTitle: error?.localizedDescription ?? "Unknown error")
                }
            }
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
            let namedWatchlists = searchText.isEmpty ? watchlists.data : watchlists.data.filter { watchlist in
                watchlist.name.localizedCaseInsensitiveContains(searchText)
            }
            
            if(namedWatchlists.isEmpty) {
                ExpandedView(geometry: geometry) {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                Section(header: Spacer(minLength: 0).listRowInsets(EdgeInsets())) {
                    ForEach(namedWatchlists) { watchlist in
                        Button(
                            action: {
                                addItemToWatchlist(watchlist: watchlist)
                            },
                            label: {
                                WatchlistCardView(watchlist: watchlist)
                            }
                        )
                        .accentColor(colorScheme == .dark ? .white : .black)
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
    
    private func addItemToWatchlist(watchlist: Watchlist) {
        self.errorToast = false
        self.loadingTitle = "Adding item to watchlist..."
        self.loadingToast = true
        Task {
            do {
                try await libraryController.addWatchlistItem(watchlist: watchlist, whatchlistEntry: item)
                self.loadingToast = false
                onDismiss(true)
            } catch let error {
                self.loadingToast = false
                self.errorTitle = "Cannot add item to watchlist"
                self.error = error
                self.errorToast = true
            }
        }
    }
    
    @ViewBuilder
    private func newWatchlistDialog() -> some View {
        TextField("Name", text: $watchlistName)
        Button("Create") {
            self.errorToast = false
            self.loadingTitle = "Creating watchlist..."
            self.loadingToast = true
            Task {
                do {
                    let name = watchlistName
                    watchlistName = ""
                    try await libraryController.createWatchlist(name: name)
                    self.loadingToast = false
                }catch let error {
                    self.loadingToast = false
                    self.errorTitle = "Cannot create watchlist"
                    self.error = error
                    self.errorToast = true
                }
            }
        }
        Button("Cancel", role: .cancel) {
            watchlistName = ""
        }
    }
}
