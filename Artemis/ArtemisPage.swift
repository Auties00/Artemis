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
    case series(DescriptableEntry, lastWatchedEpisode: Episode? = nil)
    case librarySection(LibraryPageType)
    case searchResult(SearchEntry)
    case scheduleEntry(String)
}

enum LibraryPageType: Hashable {
    case watchlists
    case watchlist(Watchlist)
    case history
    case downloads
    case download(DownloadedEntry)
}
