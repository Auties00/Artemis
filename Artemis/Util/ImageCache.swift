//
//  ImageCache.swift
//  Hidive
//
//  Created by Alessandro Autiero on 25/07/24.
//
//  This class is used to cache all the images that the app uses

import Foundation
import SwiftUI

class ImageCache {
    static let shared: ImageCache = ImageCache()
    
    private var cache: [String:Task<Data?,Error>] = [:]
    private let cacheLock: NSLock
    init() {
        self.cache = [:]
        self.cacheLock = NSLock()
    }

    func getImageData(url: ThumbnailEntry?) async throws -> Data? {
        guard let url = url else {
            return nil
        }
        
        switch(url) {
        case .url(let url):
            return try await getImageData(url: URL(string: url))
        case .data(let data):
            return data
        }
    }
    
    func getImageData(url: String?) async throws -> Data? {
        guard let url = url else {
            return nil
        }
        
        return try await getImageData(url: URL(string: url))
    }
        
    func getImageData(url: URL?) async throws -> Data? {
        guard let url = url else {
            return nil
        }
        
        let urlString = url.absoluteString
        let task = cacheLock.withLock {
            if let cached = cache[urlString] {
                return cached
            }
            
            let result = Task<Data?, Error> {
                let request = URLRequest(url: url)
                let (responseData, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if(httpResponse.statusCode != 200) {
                        throw RequestError.invalidResponseData()
                    }
                }
                return responseData
            }
            
            cache[urlString] = result
            return result
        }
        
        do {
            return try await task.value
        }catch let error {
            let _ = cacheLock.withLock {
                cache.removeValue(forKey: urlString)
            }
            throw error
        }
    }
}
