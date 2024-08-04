//
//  EpisodePlayerView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 18/07/24.
//

import SwiftUI
import AVKit
import UIKit

class EpisodePlayerController: AVPlayerViewController, AVAssetResourceLoaderDelegate {
    private let defaultUrlScheme: String = "https"
    private let playlistUrlScheme: String = "playlist"
    private let subtitlesUrlScheme: String = "subtitles"
    private let fairplayUrlScheme: String = "skd"
    private let m3u8Extension = "m3u8"
    private let vttExtension = "vtt"
    
    private var episodable: Episodable!
    private var episode: Descriptable
    private var nextEpisodes: [Descriptable & Validatable]
    private let animeController: AnimeController
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var hlsStream: PlaybackEntry!
    private var nextButton: UIView?
    
    init(episodable: (any Episodable)?, episode: Episode, animeController: AnimeController) {
        self.episodable = episodable
        self.episode = episode
        self.animeController = animeController
        self.nextEpisodes = []
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        super.init(nibName: nil, bundle: nil)
        self.entersFullScreenWhenPlaybackBegins = true
        self.exitsFullScreenWhenPlaybackEnds = true
        self.allowsPictureInPicturePlayback = true
        self.canStartPictureInPictureAutomaticallyFromInline = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        Task.detached {
            await self.preparePlayer()
        }
    }
    
    private func preparePlayer() async {
        do {
            let vod = try await self.animeController.getVod(id: self.episode.id)
            if(self.episodable == nil) {
                let episodable = try await self.animeController.getSeason(id: vod.episodeInformation!.season)
                await MainActor.run {
                    self.episodable = episodable
                }
            }
            
            if(self.nextEpisodes.isEmpty) {
                let vodsResponse = try await self.animeController.getAdjacentVods(id: self.episode.id)
                if let nextVods = vodsResponse.followingVods {
                    self.nextEpisodes.append(contentsOf: nextVods)
                }
            }
            
            let playback = try await self.animeController.getPlayback(vod: vod)
            let result = playback.hls.first { $0.drm.keySystems.contains("FAIRPLAY") }!
            await MainActor.run {
                self.hlsStream = result
            }
            
            guard let assetUrl = URL(string: self.hlsStream.url.replacing(self.defaultUrlScheme, with: self.playlistUrlScheme, maxReplacements: 1)) else {
                return
            }
            
            let asset = AVURLAsset(url: assetUrl)
            asset.resourceLoader.setDelegate(self, queue: DispatchQueue(label: "resourceLoader"))
            let playerItem = AVPlayerItem(asset: asset)
            
            let artworkItem = AVMutableMetadataItem()
            artworkItem.identifier = .commonIdentifierArtwork
            
            if let thumbnail = try await ImageCache.shared.getImageData(url: self.episode.coverUrl) {
                artworkItem.value = thumbnail as NSData
                artworkItem.dataType = kCMMetadataBaseDataType_JPEG as String
                playerItem.externalMetadata.append(artworkItem)
            }
            
            
            let titleItem = AVMutableMetadataItem()
            titleItem.identifier = .commonIdentifierTitle
            titleItem.value = self.episode.title as NSString
            playerItem.externalMetadata.append(titleItem)
            
            let seriesItem = AVMutableMetadataItem()
            seriesItem.identifier = .iTunesMetadataTrackSubTitle
            seriesItem.value = self.episodable.parentTitle as NSString
            seriesItem.locale = Locale.current
            playerItem.externalMetadata.append(seriesItem)
            
            playerItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
            
            if(self.player == nil) {
                let player = AVPlayer(playerItem: playerItem)
                player.appliesMediaSelectionCriteriaAutomatically = true
                await MainActor.run {
                    self.player = player
                }
            }else {
                self.player?.replaceCurrentItem(with: playerItem)
            }
            
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback)
            try audioSession.setActive(true, options: [])
            self.player?.play()
        }catch let error {
            print("Error: \(error)")
        }
    }
    
    private func addNextButton() {
        guard let controlsView = self.findView(parent: self.view, targetName: "AVMobileChromelessVolumeControlsView") else {
            return
        }
        
        guard let controlsContainerView = self.findView(parent: controlsView, targetName: "AVMobileChromelessFluidSlider") ?? nextButton else {
            return
        }
        
        guard let controlsContainerParentView = controlsContainerView.superview else {
            return
        }
        
        controlsContainerView.removeFromSuperview()
        guard let nextEpisode = nextEpisodes.first, nextEpisode.isValid else {
            controlsContainerParentView.layoutIfNeeded()
            return
        }
        
        let button: UIButton = UIButton(frame: controlsContainerParentView.frame)
        print(controlsContainerParentView.frame)
        button.backgroundColor = .clear
        button.setImage(UIImage(systemName: "forward.end", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), for: .normal)
        button.tintColor = .white
        nextButton = button
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.onNext))
        button.addGestureRecognizer(gesture)
        controlsContainerParentView.addSubview(button)
        controlsContainerParentView.didAddSubview(button)
    }
    
    @objc
    private func onNext() {
        player?.pause()
        self.episode = nextEpisodes.removeFirst()
        Task.detached {
            await self.preparePlayer()
        }
    }
    
    private func findView(parent: UIView?, targetName: String) -> UIView? {
        guard let parent = parent else {
            return nil
        }
        
        for child in parent.subviews {
            let descriptor = String(describing: child.self)
            if(descriptor.localizedCaseInsensitiveContains(targetName)) {
                return child
            }
            
            guard let nestedView = findView(parent: child, targetName: targetName) else {
                continue
            }
            
            return nestedView
        }
        
        return nil
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let playerItem = object as? AVPlayerItem else {
            return
        }
        
        if(keyPath != "status") {
            return
        }
        
        switch(playerItem.status) {
        case .readyToPlay:
            self.addNextButton()
        case .failed:
            print("ERROR: \(playerItem.error?.localizedDescription ?? "unknown")")
        default:
            print("Unknown state")
        }
    }
    
    private func printView(view: UIView, level: Int) {
        for child in view.subviews {
            print("\(String(repeating: "  ", count: level)) -> \(String(describing: child))")
            printView(view: child, level: level + 1)
        }
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel authenticationChallenge: URLAuthenticationChallenge) {
        fatalError("Authentication is not supported")
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForResponseTo authenticationChallenge: URLAuthenticationChallenge) -> Bool {
        fatalError("Authentication is not supported")
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        fatalError("Renewal is not supported")
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
        case playlistUrlScheme:
            return handleAsset(loadingRequest: loadingRequest)
        case subtitlesUrlScheme:
            return handleSubtitles(url: url, loadingRequest: loadingRequest)
        case fairplayUrlScheme:
            return handleFairplay(url: url, loadingRequest: loadingRequest)
        default:
            return false
        }
    }
    
    private func handleAsset(loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let assetLocation = loadingRequest.request.url?.absoluteString.replacing(playlistUrlScheme, with: defaultUrlScheme, maxReplacements: 1) else {
            return false
        }
        
        guard let assetUrl = URL(string: assetLocation) else {
            return false
        }
        
        if(assetUrl.pathExtension == m3u8Extension) {
            return handleM3u8Resource(assetUrl: assetUrl, loadingRequest: loadingRequest)
        } else {
            return handleRedirectedResource(assetUrl: assetUrl, loadingRequest: loadingRequest)
        }
    }
    
    private func handleSubtitles(url: URL, loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        let duration = self.player?.currentItem?.duration.seconds ?? 0
        let subtitlem3u8 = """
     #EXTM3U
     #EXT-X-VERSION:3
     #EXT-X-MEDIA-SEQUENCE:1
     #EXT-X-PLAYLIST-TYPE:VOD
     #EXT-X-ALLOW-CACHE:NO
     #EXT-X-TARGETDURATION:\(Int(duration))
     #EXTINF:\(String(format: "%.3f", duration)), no desc
     \(url.absoluteString.replacing(subtitlesUrlScheme, with: defaultUrlScheme, maxReplacements: 1).replacing(".\(m3u8Extension)", with: ".\(vttExtension)", maxReplacements: 1))
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
        request.allHTTPHeaderFields = animeController.getVodHeaders()
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
                if(line.starts(with: "#EXT-X-INDEPENDENT-SEGMENTS")) {
                    m3u8WithSubtitles += line
                    m3u8WithSubtitles += "\n"
                    let locale: Locale = .current
                    for subtitle in self.hlsStream.subtitles {
                        if subtitle.format == self.vttExtension {
                            let subtitlesName = locale.localizedString(forIdentifier: subtitle.language) ?? subtitle.language
                            let subtitlesUrl = subtitle.url
                                .replacing(self.defaultUrlScheme, with: self.subtitlesUrlScheme, maxReplacements: 1)
                                .replacing(".\(self.vttExtension)", with: ".\(self.m3u8Extension)", maxReplacements: 1)
                            m3u8WithSubtitles += "#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID=\"subs\",NAME=\"\(subtitlesName)\",LANGUAGE=\"\(subtitle.language)\",URI=\"\(subtitlesUrl)\""
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
        request.allHTTPHeaderFields = animeController.getVodHeaders()
        loadingRequest.redirect = request
        loadingRequest.response = HTTPURLResponse(url: assetUrl, statusCode: 302, httpVersion: nil, headerFields: nil)
        loadingRequest.finishLoading()
        return true
    }
    
    private func handleFairplay(url: URL, loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        do {
            guard let contentIdentifier = url.host else {
                return false
            }
            
            guard let contentIdentifierData = contentIdentifier.data(using: .utf8) else {
                return false
            }
            
            guard let drmUrl = URL(string: hlsStream.drm.url) else {
                return false
            }
            
            let authHeader = "Bearer \(self.hlsStream.drm.jwtToken)"
            
            var certificateRequest = URLRequest(url: drmUrl)
            certificateRequest.httpMethod = "GET"
            certificateRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
            let drmInfo = DRMInfoRequest(system: "com.apple.fps.1_0", keyIds: nil)
            let encodedDrmInfo = try self.encoder.encode(drmInfo)
            certificateRequest.setValue(encodedDrmInfo.base64EncodedString(), forHTTPHeaderField: "X-Drm-Info")
            
            let dataTask = URLSession.shared.dataTask(with: certificateRequest, completionHandler: { (certificateResponseData, certificateResponse, certificateError) in
                do {
                    if(certificateError != nil) {
                        loadingRequest.finishLoading(with: certificateError)
                        return
                    }
                    
                    if let certificateHttpResponse = certificateResponse as? HTTPURLResponse {
                        if(certificateHttpResponse.statusCode != 200) {
                            loadingRequest.finishLoading(with: NSError(domain: "certificateRequest", code: certificateHttpResponse.statusCode))
                            return
                        }
                    }
                    
                    guard certificateResponseData != nil, let certificateDecodedData = Data(base64Encoded: certificateResponseData!) else {
                        loadingRequest.finishLoading(with: NSError(domain: "certificateResponse", code: -2))
                        return
                    }
                    
                    let spcData = try loadingRequest.streamingContentKeyRequestData(forApp: certificateDecodedData, contentIdentifier: contentIdentifierData)
                    var licenseRequest = URLRequest(url: drmUrl)
                    licenseRequest.httpMethod = "POST"
                    licenseRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
                    licenseRequest.setValue(authHeader, forHTTPHeaderField: "CustomData")
                    let drmInfo = DRMInfoRequest(system: "com.apple.fps.1_0", keyIds: [contentIdentifier])
                    let encodedDrmInfo = try self.encoder.encode(drmInfo)
                    licenseRequest.setValue(encodedDrmInfo.base64EncodedString(), forHTTPHeaderField: "X-Drm-Info")
                    licenseRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    let drmChallenge = DRMChallengeRequest(challenge: spcData.base64EncodedString())
                    let encodedDrmChallenge = try self.encoder.encode(drmChallenge)
                    licenseRequest.httpBody = encodedDrmChallenge
                    let dataTask = URLSession.shared.dataTask(with: licenseRequest, completionHandler: { (licenseResponseData, licenseResponse, licenseError) in
                        do {
                            
                            if(licenseError != nil) {
                                loadingRequest.finishLoading(with: licenseError)
                                return
                            }
                            
                            if let licenseHttpResponse = licenseError as? HTTPURLResponse {
                                if(licenseHttpResponse.statusCode != 200) {
                                    loadingRequest.finishLoading(with: NSError(domain: "licenseRequest", code: licenseHttpResponse.statusCode))
                                    return
                                }
                            }
                            
                            let drmResponse = try self.decoder.decode(DRMResponse.self, from: licenseResponseData!)
                            loadingRequest.dataRequest?.respond(with: drmResponse.response)
                            loadingRequest.finishLoading()
                        }catch let error {
                            loadingRequest.finishLoading(with: error)
                        }
                    })
                    dataTask.resume()
                }catch let error {
                    loadingRequest.finishLoading(with: error)
                }
            })
            dataTask.resume()
            return true
        }catch let error {
            loadingRequest.finishLoading(with: error)
            return false
        }
    }
}
