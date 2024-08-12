//
//  DownloadResponse.swift
//  Hidive
//
//  Created by Alessandro Autiero on 31/07/24.
//

import Foundation

struct DownloadResponse: Decodable {
    let videoId: Int
    let playerUrlCallback: String
    let downloadId: String
}
