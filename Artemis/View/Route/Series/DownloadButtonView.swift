//
//  DownloadButton.swift
//   Artemis
//
//  Created by Alessandro Autiero on 30/07/24.
//

import SwiftUI
import SwiftData
import AVFoundation

struct DownloadButtonView: View {
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(ConnectivityController.self)
    private var connectivityController: ConnectivityController
    
    @State
    private var errorDialog: Bool = false
    
    @State
    private var errorData: Error?
    
    private let downloadEntry: DownloadableEntry
    init(downloadEntry: DownloadableEntry) {
        self.downloadEntry = downloadEntry
    }
    
    var body: some View {
        VStack {
            let activeDownload = libraryController.activeDownloads[downloadEntry.id]
            let saved = downloadEntry.isSaved
            if(saved) {
                downloaded()
            }else if let activeDownload = activeDownload {
                if(activeDownload.progress >= 1) {
                    downloaded()
                }else {
                    downloading(activeDownload: activeDownload)
                }
            } else {
                download()
            }
        }
        .alert(
            "Download error",
            isPresented: $errorDialog,
            actions: {},
            message: {
                Text(errorData?.localizedDescription ?? "Unknown error")
            }
        )
        .disabled(!connectivityController.isConnected)
    }
    
    @ViewBuilder
    private func downloaded() -> some View {
        Menu {
            if case .episode(let episode) = downloadEntry {
                Button(
                    action: {
                        EpisodePlayer.open(
                            episodable: nil,
                            episode: episode,
                            accountController: accountController,
                            animeController: animeController
                        )
                    },
                    label: {
                        Label("Play", systemImage: "play")
                    }
                )
            }
            
            Button(
                action: {
                    Task {
                        removeDownloaded()
                    }
                },
                label: {
                    Label("Delete", systemImage: "trash")
                }
            )
        } label: {
            Image(systemName: "checkmark.rectangle.stack.fill")
                .frame(width: 20, height: 20)
        }
        .highPriorityGesture(TapGesture())
        .highPriorityGesture(LongPressGesture())
    }
    
    @ViewBuilder
    private func downloading(activeDownload: ActiveDownload) -> some View {
        Menu {
            Button(
                action: {
                    Task {
                        if(activeDownload.paused) {
                            libraryController.resumeDownload(id: downloadEntry.id)
                        }else {
                            libraryController.pauseDownload(id: downloadEntry.id)
                        }
                    }
                },
                label: {
                    if(activeDownload.paused) {
                        Label("Resume", systemImage: "play")
                    }else {
                        Label("Pause", systemImage: "pause")
                    }
                }
            )
            
            Button(
                action: {
                    Task {
                        switch(downloadEntry) {
                        case .episode(let episode):
                            libraryController.removeAndCancelDownload(episode: episode)
                        case .season(let season):
                            libraryController.cancelDownload(episodable: season)
                        case .playlist(let playlist):
                            libraryController.cancelDownload(episodable: playlist)
                        }
                    }
                },
                label: {
                    Label("Cancel", systemImage: "stop")
                }
            )
        } label: {
            let progress = activeDownload.progress
            Circle()
                .stroke(.white, lineWidth: 2)
                .overlay(PieShape(progress: progress).foregroundColor(.white))
                .frame(width: 20, height: 20)
                .animation(Animation.linear, value: progress)
        }
        .highPriorityGesture(TapGesture())
        .highPriorityGesture(LongPressGesture())
    }
    
    @ViewBuilder
    private func download() -> some View {
        Button (
            action: {
                Task {
                    do {
                        try await libraryController.addDownload(downloadEntry: downloadEntry)
                    }catch let error {
                        await MainActor.run {
                            self.errorData = error
                            self.errorDialog = true
                        }
                        
                        removeDownloaded()
                    }
                }
            },
            label: {
                Image(systemName: "arrow.down")
                    .frame(width: 20, height: 20)
            }
        )
        .buttonStyle(.plain)
    }
    
    private func removeDownloaded() {
        switch(downloadEntry) {
        case .episode(let episode):
            libraryController.removeAndCancelDownload(episode: episode)
        case .season(let season):
            guard let series = season.series else {
                return
            }
            
            libraryController.removeDownload(downloadedEntry: .series(series))
        case .playlist(let playlist):
            libraryController.removeDownload(downloadedEntry: .playlist(playlist))
        }
    }
}

private struct PieShape: Shape {
    var progress: Double = 0.0
    private let startAngle: Double = (Double.pi) * 1.5
    private var endAngle: Double {
        get {
            return self.startAngle + Double.pi * 2 * self.progress
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arcCenter =  CGPoint(x: rect.size.width / 2, y: rect.size.width / 2)
        let radius = rect.size.width / 2
        path.move(to: arcCenter)
        path.addArc(center: arcCenter, radius: radius, startAngle: Angle(radians: startAngle), endAngle: Angle(radians: endAngle), clockwise: false)
        path.closeSubpath()
        
        return path
    }
}
