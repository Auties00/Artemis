//
//  Fairplay.swift
//   Artemis
//
//  Created by Alessandro Autiero on 31/07/24.
//

import Foundation
import AVFoundation

// Injects the subtitles into the m3u8 by using a custom url scheme
// It's not possible to load in another way subtitles from seperate files
class SubtitlesResourceInjector: NSObject, AVAssetResourceLoaderDelegate {
    private static let defaultUrlScheme: String = "https"
    private static let playlistUrlScheme: String = "playlist"
    private static let subtitlesUrlScheme: String = "subtitles"
    private static let m3u8Extension = "m3u8"
    private static let vttExtension = "vtt"
    
    private let playerItem: AVPlayerItem?
    private let subtitles: [Subtitle]
    init(resource: FairplayResource) {
        self.playerItem = resource.playerItem
        self.subtitles = resource.hlsStream?.subtitles ?? []
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        let _ = handleResource(loadingRequest: loadingRequest)
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        return handleResource(loadingRequest: loadingRequest)
    }
    
    private func handleResource(loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else {
            return false
        }
        
        switch(url.scheme) {
        case SubtitlesResourceInjector.playlistUrlScheme:
            return handleAsset(loadingRequest: loadingRequest)
        case SubtitlesResourceInjector.subtitlesUrlScheme:
            return handleSubtitles(url: url, loadingRequest: loadingRequest)
        default:
            return false
        }
    }
    
    private func handleAsset(loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let assetLocation = loadingRequest.request.url?.absoluteString.replacing(SubtitlesResourceInjector.playlistUrlScheme, with: SubtitlesResourceInjector.defaultUrlScheme, maxReplacements: 1) else {
            return false
        }
        
        guard let assetUrl = URL(string: assetLocation) else {
            return false
        }
        
        if(assetUrl.pathExtension == SubtitlesResourceInjector.m3u8Extension) {
            return handleM3u8Resource(assetUrl: assetUrl, loadingRequest: loadingRequest)
        } else {
            return handleRedirectedResource(assetUrl: assetUrl, loadingRequest: loadingRequest)
        }
    }
    
    private func handleSubtitles(url: URL, loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let duration = playerItem?.duration.seconds else {
            return false
        }
        
        let modifiedUrl = url.absoluteString
            .replacing(SubtitlesResourceInjector.subtitlesUrlScheme, with: SubtitlesResourceInjector.defaultUrlScheme, maxReplacements: 1)
            .replacing(".\(SubtitlesResourceInjector.m3u8Extension)", with: ".\(SubtitlesResourceInjector.vttExtension)", maxReplacements: 1)
        let subtitlem3u8 = """
     #EXTM3U
     #EXT-X-VERSION:3
     #EXT-X-MEDIA-SEQUENCE:1
     #EXT-X-PLAYLIST-TYPE:VOD
     #EXT-X-ALLOW-CACHE:NO
     #EXT-X-TARGETDURATION:\(Int(duration))
     #EXTINF:\(String(format: "%.3f", duration)), no desc
     \(modifiedUrl)
     #EXT-X-ENDLIST
     """
        guard let subtitlem3u8Data = subtitlem3u8.data(using: .utf8) else {
            return false
        }
        
        loadingRequest.dataRequest?.respond(with: subtitlem3u8Data)
        loadingRequest.finishLoading()
        return true
    }
    
    private func handleM3u8Resource(assetUrl: URL, loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        var request = URLRequest(url: assetUrl)
        request.httpMethod = "GET"
        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (responseData, response, error) in
            if(error != nil) {
                loadingRequest.finishLoading(with: error)
                return
            }
            
            if let m3u8HttpResponse = response as? HTTPURLResponse {
                if(m3u8HttpResponse.statusCode != 200) {
                    loadingRequest.finishLoading(with: NSError(domain: "m3u8Request", code: m3u8HttpResponse.statusCode))
                    return
                }
            }
            
            guard responseData != nil, let m3u8: String = String(data: responseData!, encoding: .utf8) else {
                loadingRequest.finishLoading(with: NSError(domain: "m3u8Response", code: -2))
                return
            }
            
            var m3u8WithSubtitles = ""
            for line in m3u8.split(separator: "\n") {
                if(line.starts(with: "#EXTM3U")) {
                    m3u8WithSubtitles += line
                    m3u8WithSubtitles += "\n"
                    let locale: Locale = .current
                    for subtitle in self.subtitles {
                        if subtitle.format == SubtitlesResourceInjector.vttExtension {
                            let subtitlesName = locale.localizedString(forIdentifier: subtitle.language) ?? subtitle.language
                            let subtitlesUrl = subtitle.url
                                .replacing(SubtitlesResourceInjector.defaultUrlScheme, with: SubtitlesResourceInjector.subtitlesUrlScheme, maxReplacements: 1)
                                .replacing(".\(SubtitlesResourceInjector.vttExtension)", with: ".\(SubtitlesResourceInjector.m3u8Extension)", maxReplacements: 1)
                            m3u8WithSubtitles += "#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID=\"subs\",NAME=\"\(subtitlesName)\",LANGUAGE=\"\(subtitle.language)\",AUTOSELECT=NO,DEFAULT=NO,FORCED=NO,URI=\"\(subtitlesUrl)\""
                            m3u8WithSubtitles += "\n"
                        }
                    }
                }else if(line.starts(with: "#EXT-X-STREAM-INF:")) {
                    m3u8WithSubtitles += "\(line),SUBTITLES=\"subs\""
                    m3u8WithSubtitles += "\n"
                }else {
                    m3u8WithSubtitles += line
                    m3u8WithSubtitles += "\n"
                }
            }
            
            guard let m3u8Data = m3u8WithSubtitles.data(using: .utf8) else {
                loadingRequest.finishLoading(with: NSError(domain: "m3u8Response", code: -3))
                return
            }
            
            loadingRequest.dataRequest?.respond(with: m3u8Data)
            loadingRequest.finishLoading()
        })
        dataTask.resume()
        return true
    }
    
    private func handleRedirectedResource(assetUrl: URL, loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        var request = URLRequest(url: assetUrl)
        request.httpMethod = "GET"
        loadingRequest.redirect = request
        loadingRequest.response = HTTPURLResponse(url: assetUrl, statusCode: 302, httpVersion: nil, headerFields: nil)
        loadingRequest.finishLoading()
        return true
    }
}

// Handles fairplay decryption, both online and offline
class FairplayContentKeySessionHandler: NSObject, AVContentKeySessionDelegate {
    private static let defaultUrlScheme: String = "https"
    private static let playlistUrlScheme: String = "playlist"
    private static let subtitlesUrlScheme: String = "subtitles"
    private static let m3u8Extension = "m3u8"
    private static let vttExtension = "vtt"
    private static let offlineCertificateKey = "fairplay_key"
    
    private var resource: FairplayResource
    private let hlsStream: PlaybackEntry?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    init(resource: FairplayResource) {
        self.resource = resource
        self.hlsStream = resource.hlsStream
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }
    
    static func createAsset(hlsStream: PlaybackEntry) -> AVURLAsset? {
        guard let assetUrl = URL(string: hlsStream.url.replacing(defaultUrlScheme, with: playlistUrlScheme, maxReplacements: 1)) else {
            return nil
        }
        
        return AVURLAsset(url: assetUrl)
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        if case .onlinePlayback = resource {
            guard let contentIdentifierString = keyRequest.identifier as? String else {
                return
            }
            
            let contentIdentifier = contentIdentifierString.replacing("skd://", with: "", maxReplacements: 1)
            handleOnlineFairplay(contentIdentifier: contentIdentifier, loadingRequest: keyRequest)
        } else {
            keyRequest.respondByRequestingPersistableContentKeyRequest()
        }
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) {
        guard let contentIdentifierString = keyRequest.identifier as? String else {
            return
        }
        
        let contentIdentifier = contentIdentifierString.replacing("skd://", with: "", maxReplacements: 1)
        switch(resource) {
        case .onlinePlayback:
            fatalError("Online playback is not persistent")
        case .offlinePlayback:
            handleOfflineFairplay(contentIdentifier: contentIdentifier, loadingRequest: keyRequest)
        case .download:
            handleOnlineFairplay(contentIdentifier: contentIdentifier, loadingRequest: keyRequest)
        }
    }
    
    private func handleOfflineFairplay(contentIdentifier: String, loadingRequest: AVContentKeyRequest) {
        guard let cachedLicenseBase64 = UserDefaults.standard.string(forKey: "\(FairplayContentKeySessionHandler.offlineCertificateKey)_\(contentIdentifier)") else {
            return
        }
        
        guard let cachedLicense = Data(base64Encoded: cachedLicenseBase64) else {
            return
        }
        
        let response = AVContentKeyResponse(fairPlayStreamingKeyResponseData: cachedLicense)
        loadingRequest.processContentKeyResponse(response)
    }
    
    private func handleOnlineFairplay(contentIdentifier: String, loadingRequest: AVContentKeyRequest) {
        do {
            guard let hlsStream = hlsStream else {
                return
            }
            
            guard let contentIdentifierData = contentIdentifier.data(using: .utf8) else {
                return
            }
            
            guard let drmUrl = URL(string: hlsStream.drm.url) else {
                return
            }
            
            let authHeader = "Bearer \(hlsStream.drm.jwtToken)"
            
            var certificateRequest = URLRequest(url: drmUrl)
            certificateRequest.httpMethod = "GET"
            certificateRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
            let drmInfo = DRMInfoRequest(system: "com.apple.fps.1_0", keyIds: nil)
            let encodedDrmInfo = try self.encoder.encode(drmInfo)
            certificateRequest.setValue(encodedDrmInfo.base64EncodedString(), forHTTPHeaderField: "X-Drm-Info")
            
            let dataTask = URLSession.shared.dataTask(with: certificateRequest, completionHandler: { (certificateResponseData, certificateResponse, certificateError) in
                if let certificateError = certificateError {
                    loadingRequest.processContentKeyResponseError(certificateError)
                    return
                }
                
                if let certificateHttpResponse = certificateResponse as? HTTPURLResponse {
                    if(certificateHttpResponse.statusCode != 200) {
                        loadingRequest.processContentKeyResponseError(NSError(domain: "certificateRequest", code: certificateHttpResponse.statusCode))
                        return
                    }
                }
                
                guard certificateResponseData != nil, let certificateDecodedData = Data(base64Encoded: certificateResponseData!) else {
                    loadingRequest.processContentKeyResponseError(NSError(domain: "certificateResponse", code: -2))
                    return
                }
                
                
                loadingRequest.makeStreamingContentKeyRequestData(forApp: certificateDecodedData, contentIdentifier: contentIdentifierData) { (spcData, spcError) in
                    do {
                        if let spcError = spcError {
                            loadingRequest.processContentKeyResponseError(spcError)
                            return
                        }
                        
                        var licenseRequest = URLRequest(url: drmUrl)
                        licenseRequest.httpMethod = "POST"
                        licenseRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
                        licenseRequest.setValue(authHeader, forHTTPHeaderField: "CustomData")
                        let drmInfo = DRMInfoRequest(system: "com.apple.fps.1_0", keyIds: [contentIdentifier])
                        let encodedDrmInfo = try self.encoder.encode(drmInfo)
                        licenseRequest.setValue(encodedDrmInfo.base64EncodedString(), forHTTPHeaderField: "X-Drm-Info")
                        licenseRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                        let drmChallenge = DRMChallengeRequest(challenge: spcData!.base64EncodedString())
                        let encodedDrmChallenge = try self.encoder.encode(drmChallenge)
                        licenseRequest.httpBody = encodedDrmChallenge
                        let dataTask = URLSession.shared.dataTask(with: licenseRequest, completionHandler: { (licenseResponseData, licenseResponse, licenseError) in
                            do {
                                if let licenseError = licenseError {
                                    loadingRequest.processContentKeyResponseError(licenseError)
                                    return
                                }
                                
                                if let licenseHttpResponse = licenseError as? HTTPURLResponse {
                                    if(licenseHttpResponse.statusCode != 200) {
                                        loadingRequest.processContentKeyResponseError(NSError(domain: "licenseRequest", code: licenseHttpResponse.statusCode))
                                        return
                                    }
                                }
                                
                                let drmResponse = try self.decoder.decode(DRMResponse.self, from: licenseResponseData!)
                                if let persistentLoadingRequest = loadingRequest as? AVPersistableContentKeyRequest {
                                    let persistent = try persistentLoadingRequest.persistableContentKey(fromKeyVendorResponse: drmResponse.response)
                                    UserDefaults.standard.set(persistent.base64EncodedString(), forKey: "\(FairplayContentKeySessionHandler.offlineCertificateKey)_\(contentIdentifier)")
                                    let response = AVContentKeyResponse(fairPlayStreamingKeyResponseData: persistent)
                                    loadingRequest.processContentKeyResponse(response)
                                }else {
                                    let response = AVContentKeyResponse(fairPlayStreamingKeyResponseData: drmResponse.response)
                                    loadingRequest.processContentKeyResponse(response)
                                }
                            }catch let error {
                                loadingRequest.processContentKeyResponseError(error)
                            }
                        })
                        dataTask.resume()
                    }catch let error {
                        loadingRequest.processContentKeyResponseError(error)
                    }
                }
            })
            dataTask.resume()
        }catch let error {
            loadingRequest.processContentKeyResponseError(error)
        }
    }
}

// A resource to be consumed by the fairplay handler
enum FairplayResource {
    case onlinePlayback(PlaybackEntry, AVPlayerItem)
    case offlinePlayback(AVPlayerItem)
    case download(PlaybackEntry)
    
    var playerItem: AVPlayerItem? {
        switch(self) {
        case .onlinePlayback(_, let playerItem):
            return playerItem
        case .offlinePlayback(let playerItem):
            return playerItem
        case .download:
            return nil
        }
    }
    
    var hlsStream: PlaybackEntry? {
        switch(self) {
        case .onlinePlayback(let hlsStream, _):
            return hlsStream
        case .offlinePlayback(_):
            return nil
        case .download(let hlsStream):
            return hlsStream
        }
    }
}
