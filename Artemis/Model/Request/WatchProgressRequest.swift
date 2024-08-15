//
//  WatchProgressRequest.swift
//  Hidive
//
//  Created by Alessandro Autiero on 10/08/24.
//

import Foundation

struct WatchProgressRequest: Encodable {
    let video: Int
    let cid: String
    let startedAt: Int64
    let action: Int
    let ctx: Int
    let progress: Int
    let nature: String?
}
