//
//  DownloadsView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 20/07/24.
//

import SwiftUI

struct DownloadsView: View {
    private static let headerId: String = "downloadsHeader"
    
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    @State
    private var searchText: String = ""
    
    @State
    private var shouldScrollToHeader: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            loadedBody(geometry: geometry)
        }
        .navigationTitle("Downloads")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }
    
    @ViewBuilder
    private func loadedBody(geometry: GeometryProxy) -> some View {
        ScrollViewReader { scrollProxy in
            List {
                if(!accountController.isLoggedIn()) {
                    ExpandedView(geometry: geometry) {
                        ContentUnavailableView(
                            "No downloads",
                            systemImage: "arrow.down.circle.fill",
                            description: Text("Only registered users can view their downloads")
                        )
                    }
                }else {
                    var downloads = Array(libraryController.downloads.values)
                    if(downloads.isEmpty) {
                        ExpandedView(geometry: geometry) {
                            ContentUnavailableView(
                                "No downloads",
                                systemImage: "arrow.down.circle.fill",
                                description: Text("Your downloads will be displayed here")
                            )
                        }
                    } else {
                        let filteredDownloads = searchText.isEmpty ? downloads : downloads.filter {
                            $0.wrappedValue.title.localizedCaseInsensitiveContains(searchText)
                        }
                        if(filteredDownloads.isEmpty) {
                            ExpandedView(geometry: geometry) {
                                ContentUnavailableView.search(text: searchText)
                            }
                        }else {
                            Section(
                                header: Spacer(minLength: 0)
                                    .listRowInsets(EdgeInsets())
                                    .onAppear {
                                        self.shouldScrollToHeader = false
                                    }
                                    .onDisappear {
                                        self.shouldScrollToHeader = true
                                    }
                                    .id(DownloadsView.headerId)
                            ) {
                                ForEach(downloads) { download in
                                    downloadCard(download: download)
                                }
                                .onDelete {
                                    var removedDownloads: [DownloadedEntry] = []
                                    for index in $0 {
                                        let removed = downloads.remove(at: index)
                                        removedDownloads.append(removed)
                                    }
                                    
                                    for removedDownload in removedDownloads {
                                        libraryController.removeDownload(downloadedEntry: removedDownload)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                routerController.pathHandler = {
                    if(shouldScrollToHeader) {
                        withAnimation {
                            scrollProxy.scrollTo(DownloadsView.headerId, anchor: .center)
                        }
                        
                        return true
                    }
                    
                    return false
                }
            }
            .environment(\.defaultMinListHeaderHeight, 12)
            .listRowSpacing(12)
        }
    }
    
    @ViewBuilder
    private func downloadCard(download: DownloadedEntry) -> some View {
        NavigationLink(value: NestedPageType.librarySection(.download(download))) {
            HStack(alignment: .top) {
                if let thumbnailUrl = download.wrappedValue.coverUrl {
                    NetworkImage(
                        thumbnailEntry: thumbnailUrl,
                        width: 175,
                        height: 100
                    )
                } else {
                    Image(systemName: "camera.metering.unknown")
                        .frame(width: 175, height: 100)
                        .background(Material.thin)
                        .cornerRadius(8)
                }
                
                Spacer()
                    .frame(width: 12)
                
                VStack(alignment: .leading) {
                    Text(download.wrappedValue.parentTitle)
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .lineLimit(4)
                    
                    let _ = libraryController.activeDownloads // Observe active downloads so downloadedEpisodes remains updated
                    let downloadedEpisodes = download.savedEpisodesCount
                    Text("\(downloadedEpisodes == 0 ? "No" : "\(downloadedEpisodes)") episode\(downloadedEpisodes != 1 ? "s" : "") downloaded")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
