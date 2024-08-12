//
//  Download.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/08/24.
//

import Foundation
import AVFoundation

@Observable
class ActiveDownload {
    var downloadTask: AVAssetDownloadTask?
    var subtitlesInjector: SubtitlesResourceInjector?
    var fairplaySessionHandler: FairplayContentKeySessionHandler?
    var fairplaySession: AVContentKeySession?
    var resourceSaver: OfflineResourceSaver?
    var observer: NSObject?
    var progress: Double = 0
    var paused: Bool = false
    var cancelled: Bool = false
    var childHandler: (() -> Void)?
    var childrenIds: [Int] = []
}
