//
//  EpisodePlayerView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 18/07/24.
//

import SwiftUI
import AVKit
import UIKit

class EpisodePlayer: AVPlayerViewController {
    private var playerId: String
    private var episodable: (any Episodable)!
    private var episode: Episode
    private var nextEpisodes: [Episode]
    private let accountController: AccountController
    private let animeController: AnimeController
    private let onDismiss: ((Episode) -> Void)?
    private var nextButton: UIView?
    private var lastNextButtonClick: TimeInterval!
    private var asset: AVURLAsset!
    private var subtitlesInjector: AVAssetResourceLoaderDelegate!
    private var fairplaySession: AVContentKeySession!
    private var fairplayHandler: AVContentKeySessionDelegate!
    private var statusObserver: NSObject?
    private var languageObserver: (any NSObjectProtocol)?
    private var watchProgressObserver: Any?
    
    static func open(episodable: Episodable?, episode: Episode, nextEpisodes: [Episode]? = nil, accountController: AccountController, animeController: AnimeController, onDismiss: ((Episode) -> Void)? = nil) {
        let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene

        let rootViewController = scene?
            .windows.first(where: { $0.isKeyWindow })?
            .rootViewController
        
        let player = EpisodePlayer(episodable: episodable, episode: episode, nextEpisodes: nextEpisodes, accountController: accountController, animeController: animeController, onDismiss: onDismiss)
        rootViewController?.present(player, animated: true)
    }
    
    private init(episodable: Episodable?, episode: Episode, nextEpisodes: [Episode]? = nil, accountController: AccountController, animeController: AnimeController, onDismiss: ((Episode) -> Void)?) {
        self.playerId = UUID().uuidString
        self.episodable = episodable
        self.episode = episode
        self.accountController = accountController
        self.animeController = animeController
        self.nextEpisodes = nextEpisodes ?? []
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
        self.entersFullScreenWhenPlaybackBegins = true
        self.exitsFullScreenWhenPlaybackEnds = false
        self.allowsPictureInPicturePlayback = true
        self.canStartPictureInPictureAutomaticallyFromInline = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        Task {
            await self.preparePlayer()
        }
    }
    
    private func preparePlayer() async {
        guard let playerItem = await createPlayerItem() else {
            return
        }
        
        if(self.nextEpisodes.isEmpty) {
            if let response = try? await self.animeController.getAdjacentEpisodes(id: self.episode.id) {
                if let nextEpisodes = response.following {
                    self.nextEpisodes.append(contentsOf: nextEpisodes)
                }
            }
        }
        
        self.statusObserver = playerItem.observe(\.status) { item, _ in
            self.handleStatus(item: item)
        }
        
        self.languageObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.mediaSelectionDidChangeNotification, object: playerItem, queue: OperationQueue.main) { data in
            guard let item = data.object as? AVPlayerItem else {
                return
            }
            
            self.handleLanguage(item: item)
        }
        
        await beautifyPlayerItem(playerItem: playerItem)
        
        if(self.player == nil) {
            let player = AVPlayer(playerItem: playerItem)
            let interval = CMTime(seconds: 15, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            self.watchProgressObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { time in
                self.saveProgress(last: false)
            }
            
            player.actionAtItemEnd = .none
            player.appliesMediaSelectionCriteriaAutomatically = true
            await MainActor.run {
                self.player = player
            }
            NotificationCenter.default.addObserver(self, selector: #selector(onNext), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        }else {
            nextButton?.removeFromSuperview()
            self.player?.replaceCurrentItem(with: playerItem)
        }
        
        if let watchProgress = episode.watchProgress {
            await self.player?.seek(to: CMTime(value: Int64(watchProgress), timescale: 1))
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback)
        try? audioSession.setActive(true, options: [])
        
        self.player?.play()
    }
    
    private nonisolated func handleStatus(item: AVPlayerItem) {
        Task {
            switch(item.status) {
            case .readyToPlay:
                await self.addNextButton()
                await self.configurePlayerItemLocale(playerItem: item)
            case .failed:
                await MainActor.run {
                    self.showError(error: item.error?.localizedDescription ?? "Unknown error")
                }
            default:
                break
            }
        }
    }
    
    private nonisolated func handleLanguage(item: AVPlayerItem) {
        Task {
            var audioLocale: String?
            if let audioGroup = try? await item.asset.loadMediaSelectionGroup(for: AVMediaCharacteristic.audible) {
                let selectedOption = item.currentMediaSelection.selectedMediaOption(in: audioGroup)
                audioLocale = selectedOption?.locale?.identifier
            }
            
            guard let audioLocale = audioLocale else {
                return
            }
            
            var subtitlesLocale: String?
            if let subtitlesGroup = try? await item.asset.loadMediaSelectionGroup(for: AVMediaCharacteristic.legible) {
                let selectedOption = item.currentMediaSelection.selectedMediaOption(in: subtitlesGroup)
                subtitlesLocale = selectedOption?.locale?.identifier
            }
            
            if case .success(let profile) = accountController.profile, let profile = profile {
                profile.preferences.audioLanguage = audioLocale
                profile.preferences.subtitlesLanguage = subtitlesLocale ?? "false"
                try? await accountController.updateProfile(profile: profile)
            }
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) {
            if let watchProgressObserver = self.watchProgressObserver {
                self.player?.removeTimeObserver(watchProgressObserver)
                self.watchProgressObserver = nil
            }
            
            self.saveProgress(last: true)
            
            self.statusObserver = nil
            self.languageObserver = nil
            
            self.accountController.addContinueWatching(episode: self.episode)
            self.onDismiss?(self.episode)
            
            completion?()
        }
    }
    
    private func createPlayerItem() async -> AVPlayerItem? {
        if let localFile = OfflineResourceSaver.getResource(id: episode.id) {
            let asset = AVURLAsset(url: localFile)
            let playerItem = AVPlayerItem(asset: asset)
            let resource = FairplayResource.offlinePlayback(playerItem)
            self.subtitlesInjector = SubtitlesResourceInjector(resource: resource)
            self.fairplaySession = AVContentKeySession(keySystem: .fairPlayStreaming)
            fairplaySession.addContentKeyRecipient(asset)
            asset.resourceLoader.preloadsEligibleContentKeys = true
            asset.resourceLoader.setDelegate(subtitlesInjector, queue: DispatchQueue.main)
            fairplayHandler = FairplayContentKeySessionHandler(resource: resource)
            fairplaySession.setDelegate(fairplayHandler, queue: DispatchQueue.main)
            
            return playerItem
        }else {
            guard let episode = try? await self.animeController.getEpisode(id: self.episode.id, includePlayback: true) else {
                showError(error: "Cannot query episode")
                return nil
            }
            
            if self.episodable == nil, let episodeInformation = episode.episodeInformation {
                await MainActor.run {
                    self.episodable = episodeInformation.season
                }
            }
            
            guard let hlsStream = try? await self.animeController.getFairplayPlayback(episode: episode) else {
                showError(error: "Cannot query hls stream")
                return nil
            }
            
            guard let asset = FairplayContentKeySessionHandler.createAsset(hlsStream: hlsStream) else {
                showError(error: "Cannot create hls stream asset")
                return nil
            }
            
            let playerItem = AVPlayerItem(asset: asset)
            let resource = FairplayResource.onlinePlayback(hlsStream, playerItem)
            self.subtitlesInjector = SubtitlesResourceInjector(resource: resource)
            self.fairplaySession = AVContentKeySession(keySystem: .fairPlayStreaming)
            fairplaySession.addContentKeyRecipient(asset)
            asset.resourceLoader.preloadsEligibleContentKeys = true
            asset.resourceLoader.setDelegate(subtitlesInjector, queue: DispatchQueue.main)
            fairplayHandler = FairplayContentKeySessionHandler(resource: resource)
            fairplaySession.setDelegate(fairplayHandler, queue: DispatchQueue.main)
            
            return playerItem
        }
    }
    
    private func beautifyPlayerItem(playerItem: AVPlayerItem) async {
        let artworkItem = AVMutableMetadataItem()
        artworkItem.identifier = .commonIdentifierArtwork
        if let thumbnail = try? await ImageCache.shared.getImageData(url: self.episode.coverUrl) {
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
    }
    
    private func configurePlayerItemLocale(playerItem: AVPlayerItem) async {
        if let offlineAudioLanguage = UserDefaults.standard.string(forKey: AccountController.offlineAudioLanguageKey) {
            if let group = try? await playerItem.asset.loadMediaSelectionGroup(for: .audible) {
                if let option = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: Locale(identifier: offlineAudioLanguage)).first {
                    playerItem.select(option, in: group)
                }
            }
        }
        
        if let offlineSubtitlesLanguage = UserDefaults.standard.string(forKey: AccountController.offlineSubtitlesLanguageKey) {
            if let group = try? await playerItem.asset.loadMediaSelectionGroup(for: .legible) {
                if let option = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: Locale(identifier: offlineSubtitlesLanguage)).first {
                    playerItem.select(option, in: group)
                }
            }
        }
    }
    
    private func addNextButton() {
        // The HStack of buttons at the top left
        guard let controlsView = self.findView(parent: self.view, targetName: "AVMobileChromelessDisplayModeControlsView") else {
            return
        }
        
        // The parent of the top left controls, which contains all the AVPlayer controls
        guard let controlsViewParent = controlsView.superview else {
            return
        }
        
        // The container, and theoretically only view, in controlsView, used to wrap the three buttons (close, pip, cast)
        guard let controlsContainerView = self.findView(parent: controlsView, targetName: "AVMobileChromelessContainerView") else {
            return
        }
        
        // Check if another episode exist, otherwise don't create the button
        guard let nextEpisode = self.nextEpisodes.first, nextEpisode.isValid else {
            return
        }
        
        // Create the button and add it to controlsView so it matches the animation of the other buttons
        let button: UIButton = UIButton()
        self.nextButton = button
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.setImage(UIImage(systemName: "forward.end", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
        button.tintColor = .white
        controlsView.addSubview(button)
        controlsView.didAddSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: 22),
            button.centerYAnchor.constraint(equalTo: controlsContainerView.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        // Now create a ghost above the button we just created
        // This has to be done because controlsContainerView's dimensions are inherited from controlsView, which gets resized by AVPlayer
        // If our button is outside controlsView's bounds, then we can't interact with it
        // Listening to the size change, and applying a width extension to fix this issue is possible with KVO, but Apple says not to rely on it, so this solution is probably better
        let passthrough = UIButton()
        passthrough.translatesAutoresizingMaskIntoConstraints = false
        passthrough.backgroundColor = .clear
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.onLongNext))
        longGesture.minimumPressDuration = 0
        passthrough.addGestureRecognizer(longGesture)
        controlsViewParent.addSubview(passthrough)
        controlsViewParent.didAddSubview(passthrough)
        NSLayoutConstraint.activate([
            passthrough.leadingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: 22),
            passthrough.centerYAnchor.constraint(equalTo: controlsContainerView.centerYAnchor),
            passthrough.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc
    private func onLongNext(gestureReconizer: UILongPressGestureRecognizer) {
        switch(gestureReconizer.state) {
        case .began:
            lastNextButtonClick = Date.timeIntervalSinceReferenceDate
            self.nextButton?.transform = CGAffineTransformMakeScale(0.75, 0.75)
        case .ended:
            if(Date.timeIntervalSinceReferenceDate - lastNextButtonClick < 0.1) {
                onNext()
            }
            
            self.nextButton?.transform = CGAffineTransform.identity
        default:
            break
        }
    }
    
    @objc
    private func onNext() {
        guard let nextEpisode = self.nextEpisodes.first, nextEpisode.isValid else {
            return
        }
        
        player?.pause()
        self.episode = nextEpisodes.removeFirst()
        Task {
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
    
    private nonisolated func saveProgress(last: Bool) {
        Task {
            guard let playerItem = await self.player?.currentItem else {
                return
            }
            
            let playing = await self.player?.timeControlStatus == .playing
            if(!last && !playing) {
                return
            }
            
            if let progress = await self.player?.currentTime().seconds {
                await self.episode.watchProgress = Int(progress)
                await self.episode.watchedAt = Date.now.millisecondsSince1970
            }
            
            let episodeId = await self.episode.id
            let progress = Int(playerItem.currentTime().seconds)
            try? await animeController.saveWatchProgress(cid: playerId, id: episodeId, progress: progress, last: last)
        }
    }
    
    private func showError(error: String) {
        let alert = UIAlertController(title: "Player Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { _ in
            self.dismiss(animated: false)
        })
        self.present(alert, animated: true)
    }
    
    /*
     Used during development for the next button
     The XCode debugger is so slow :/
     
     private func printView(view: UIView, level: Int) {
         for child in view.subviews {
             print("\(String(repeating: "  ", count: level)) -> \(String(describing: child))")
             printView(view: child, level: level + 1)
         }
     }
     */
}
