//
//  WatchlistsView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 20/07/24.
//

import SwiftUI

struct WatchHistoryView: View {
    @EnvironmentObject
    private var libraryController: LibraryController
    
    @State
    private var initialized: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            List {
                switch(libraryController.watchHistory) {
                case .success(let watchHistory):
                    ForEach(watchHistory) { entry in
                        Section {
                            NavigationLink(
                                destination: {
                                    Text("Hello World")
                                },
                                label: {
                                    HStack(alignment: .top, spacing: 0) {
                                        NetworkImage(url: entry.thumbnailUrl)
                                            .frame(width: 175)
                                        Spacer()
                                            .frame(width: 12)
                                        VStack(alignment: .leading) {
                                            Text(entry.title)
                                                .font(.system(size: 20))
                                                .fontWeight(.bold)
                                                .lineLimit(2)
                                            Text(entry.description)
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                                .lineLimit(3)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            )
                        }
                    }
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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if(!initialized) {
                    await libraryController.loadWatchHistory()
                    initialized = true
                }
            }
        }
    }
}
