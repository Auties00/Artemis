//
//  WatchlistsResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 27/07/24.
//

import Foundation

class WatchlistsResponse: Decodable {
    let watchlists: [Watchlist]
    let pagingInfo: Paging
}
