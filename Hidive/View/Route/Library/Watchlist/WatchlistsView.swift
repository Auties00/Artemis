//
//  WatchlistsView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 27/07/24.
//

import SwiftUI

struct WatchlistsView: View {
    @EnvironmentObject
    private var libraryController: LibraryController
    
    @State
    private var initialized: Bool = false
    
    @State
    private var createWatchlistDialog: Bool = false
    
    @State
    private var newWatchlistName: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            List {
                switch(libraryController.watchlists) {
                case .success(let watchlists):
                    loadedBody(watchlists: watchlists)
                case .loading, .empty:
                    ExpandedView(geometry: geometry) {
                        LoadingView()
                    }
                case .failure(let error):
                    ExpandedView(geometry: geometry) {
                        ErrorView(error: error)
                    }
                }
            }
            .alert("New watchlist", isPresented: $createWatchlistDialog) {
                TextField("Name", text: $newWatchlistName)
                Button("Create") {
                    Task {
                        do {
                            let name = newWatchlistName
                            createWatchlistDialog.toggle()
                            newWatchlistName = ""
                            try await libraryController.createWatchlist(name: name)
                        }catch let error {
                            print("Error: \(error)")
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    createWatchlistDialog.toggle()
                    newWatchlistName = ""
                }
            }
            .navigationTitle("Watchlists")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button(
                    action: {
                        print("Called")
                        createWatchlistDialog.toggle()
                    },
                    label: {
                        Image(systemName: "plus")
                    }
                )
            )
            .task {
                if(!initialized) {
                    await libraryController.loadWatchlists()
                    initialized = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func loadedBody(watchlists: [Watchlist]) -> some View {
        ForEach(watchlists) { watchlist in
            Section {
                NavigationLink(
                    destination: {
                        Text("Hello World")
                    },
                    label: {
                        HStack(alignment: .top) {
                            if let thumbnailUrl = watchlist.thumbnails.first {
                                NetworkImage(url: thumbnailUrl)
                                    .frame(width: 175, height: 100)
                            } else {
                                Image(systemName: "camera.metering.unknown")
                                    .frame(width: 175, height: 100)
                                    .background(Material.thin)
                                    .cornerRadius(6)
                            }
                            
                            Spacer()
                                .frame(width: 12)
                            
                            VStack(alignment: .leading) {
                                Text(watchlist.name)
                                    .font(.system(size: 20))
                                    .fontWeight(.bold)
                                    .lineLimit(4)
                                
                                Text("Created by \(watchlist.ownership == "OWNED" ? "you" : "???")")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                )
            }
            .contextMenu {
                Button {
                    // TODO: Start watching
                } label: {
                    Label("Open", systemImage: "play")
                }
                
                Button {
                    // TODO: Go to anime
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                
                Button {
                    guard let index = watchlists.firstIndex(of: watchlist) else {
                        return
                    }
                    
                    onDelete(indexSet: IndexSet(integer: index))
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .onDelete(perform: onDelete)
    }
    
    private func onDelete(indexSet: IndexSet) {
        Task {
            do {
                try await libraryController.deleteWatchlists(indexSet: indexSet)
            }catch let error {
                print("Error: \(error)")
            }
        }
    }
}
