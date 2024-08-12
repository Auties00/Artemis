//
//  AddWatchlistItemRequest.swift
//  Hidive
//
//  Created by Alessandro Autiero on 29/07/24.
//

import Foundation

struct AddWatchlistItemRequest: Encodable {
    let content: [AddWatchlistItemContent]
}

struct AddWatchlistItemContent: Encodable {
    let id: String
    let contentType: String
}
