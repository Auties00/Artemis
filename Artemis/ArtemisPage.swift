//
//   ArtemisPageType.swift
//   Artemis
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

enum RootPageType: Identifiable, CaseIterable {
    case home
    case schedule
    case library
    case search
    
    var id: Self {
        self
    }
}

enum NestedPageType: Hashable {
    case home(DescriptableEntry, lastWatchedEpisode: Episode? = nil)
    case library(LibraryPageType)
    case search(SearchEntry)
    case schedule(String)
}

enum LibraryPageType: Hashable {
    case watchlists
    case watchlist(Watchlist)
    case history
    case downloads
    case download(DownloadedEntry)
}