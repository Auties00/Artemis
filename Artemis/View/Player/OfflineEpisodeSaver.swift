//
//  OfflineResource.swift
//   Artemis
//
//  Created by Alessandro Autiero on 01/08/24.
//

import Foundation
import AVFoundation

// Saves the downloads in the correct location and resolves files that were already downloaded
class OfflineResourceSaver: NSObject, AVAssetDownloadDelegate {
    private let episode: Episode
    init(episode: Episode) {
        self.episode = episode
    }
    
    static func getResource(id: Int) -> URL? {
        guard let path = UserDefaults.standard.string(forKey: "offline_\(id)") else {
            return nil
        }
        
        let baseUrl = URL(fileURLWithPath: NSHomeDirectory())
        return baseUrl.appendingPathComponent(path)
    }
    
    static func deleteResource(id: Int) {
        if let url = OfflineResourceSaver.getResource(id: id) {
            try? FileManager.default.removeItem(at: url)
        }
        
        UserDefaults.standard.removeObject(forKey: "offline_\(id)")
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        if assetDownloadTask.error != nil {
            episode.isSaved = false
        }else {
            UserDefaults.standard.set(location.relativePath, forKey: "offline_\(episode.id)")
        }
    }
}
