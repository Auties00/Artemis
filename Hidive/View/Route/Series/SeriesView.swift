//
//  SeriesView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 18/07/24.
//

import SwiftUI
import SwiftUIIntrospect

private let defaultImageHeight: CGFloat = 573.3333333333334

struct SeriesView: View {
    private let id: Int
    private let name: String
    private let playlist: Bool
    @State
    private var navigationBarTitle = ""
    @State
    private var selectedSeasonNumber: Int
    @State
    private var holder: AsyncResult<Holder> = .empty
    @State
    private var showDescription: Bool = false
    @EnvironmentObject
    private var animeController: AnimeController
    @Environment(\.dismiss)
    private var dismiss
    @State
    private var thumbnailHeight: CGFloat = defaultImageHeight
    @State
    private var thumbnailOpacity: Double = 1
    @State
    private var lastOverscroll: CGFloat = 0
    private var scrollDelegate: ScrollViewDelegate = ScrollViewDelegate()
    
    init(id: Int, name: String, playlist: Bool, selectedSeasonNumber: Int = 1) {
        self.id = id
        self.playlist = playlist
        self.name = name
        self._selectedSeasonNumber = State(initialValue: selectedSeasonNumber)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    switch(holder) {
                    case .success(data: let data):
                        loadedBody(geometry: geometry, data: data)
                        
                    case .failure(error: let error):
                        ExpandedView(geometry: geometry) {
                            ErrorView(error: error)
                        }
                        
                    case .empty, .loading:
                        ExpandedView(geometry: geometry) {
                            ProgressView()
                        }
                    }
                }
                .introspect(.scrollView, on: .iOS(.v16, .v17, .v18), scope: .ancestor, customize: setupScrollView)
                .offset(y: -lastOverscroll)
            }
            .ignoresSafeArea(.all, edges: [.top])
            .navigationTitle(navigationBarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(!navigationBarTitle.isEmpty ? .visible : .hidden, for: .navigationBar)
            .navigationBarItems(
                leading: SeriesToolbarButtonView(iconName: "chevron.left", foregroundColor: !navigationBarTitle.isEmpty, backgroundColor: navigationBarTitle.isEmpty ? .material(.thin) : .color(.clear)) {
                    dismiss()
                },
                trailing: SeriesToolbarButtonView(iconName: "plus", foregroundColor: !navigationBarTitle.isEmpty, backgroundColor: navigationBarTitle.isEmpty ? .material(.thin) : .material(.thick)) {
                    
                }
            )
            .task {
                if case .empty = holder {
                    await loadData(selectedSeasonIndex: selectedSeasonNumber - 1)
                }
            }
            .onChange(of: selectedSeasonNumber) { oldValue, newValue in
                thumbnailOpacity = 1.0
                Task {
                    await loadData(selectedSeasonIndex: newValue - 1)
                }
            }
        }
    }
    
    @ViewBuilder
    private func loadedBody(geometry: GeometryProxy, data: Holder) -> some View {
        NetworkImage(
            url: data.episodable.posterUrl!,
            cornerRadius: 0,
            fill: true
        )
        .frame(width: geometry.size.width, height: thumbnailHeight)
        .opacity(thumbnailOpacity)
        
        Text(data.episodable.preferredDescription)
            .font(.system(size: 15))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.background.secondary)
            .clipShape(.rect(
                topLeadingRadius: 0,
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 8,
                topTrailingRadius: 0
            ))
        
        if !playlist, let series = data.series {
            HStack {
                Menu {
                    Picker("picker", selection: $selectedSeasonNumber) {
                        ForEach(1...(series.seasons?.count ?? series.seasonCount), id: \.self) { option in
                            Text("Season \(option)")
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(InlinePickerStyle())
                    
                } label: {
                    Image(systemName: "chevron.down")
                    Spacer()
                        .frame(width: 12)
                    Text("Season \(selectedSeasonNumber)")
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                Image(systemName: "arrow.down")
                    .padding(.horizontal, 24)
            }
            .accentColor(.white)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(.background.secondary)
            .cornerRadius(8)
            .padding()
        }
        
        let episodes = data.episodable.episodes?.filter { $0.isValid } ?? []
        ForEach(episodes) { episode in
            let entry = Button(
                action: {
                    EpisodePlayer.open(episodable: data.episodable, episode: episode, animeController: animeController)
                },
                label: {
                    HStack(alignment: .top, spacing: 0) {
                        NetworkImage(url: episode.thumbnailUrl)
                            .frame(width: 175)
                        Spacer()
                            .frame(width: 12)
                        VStack(alignment: .leading) {
                            Text(episode.title)
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .lineLimit(2)
                            Text(episode.description)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(.background.secondary)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            if(data.episodable.paging?.moreDataAvailable == true && episode == episodes.last) {
                let _ = print("More data may be available")
                entry.task {
                    await loadMoreData()
                }
            }else {
                entry
            }
        }
    }
    
    private func setupScrollView(scrollView: UIScrollView) {
        scrollDelegate.handler = handleScroll
        scrollView.delegate = scrollDelegate
    }
    
    private func handleScroll(scrollView: UIScrollView, scrollOffset: CGFloat) {
        if(scrollOffset < 0) {
            let overscroll = abs(scrollOffset)
            thumbnailHeight += overscroll - lastOverscroll
            lastOverscroll = overscroll
        }else {
            if(scrollOffset <= thumbnailHeight) {
                thumbnailOpacity = 1 - scrollOffset / thumbnailHeight
            }else if(thumbnailOpacity != 0) {
                thumbnailOpacity = 0
            }
            
            let collapseHeight = thumbnailHeight * 0.75
            if(navigationBarTitle.isEmpty && scrollOffset > collapseHeight) {
                withAnimation {
                    navigationBarTitle = name
                }
            }else if(!navigationBarTitle.isEmpty && scrollOffset < collapseHeight) {
                withAnimation {
                    navigationBarTitle = ""
                }
            }
        }
    }
    
    private func loadData(selectedSeasonIndex: Int) async {
        if(playlist) {
            do {
                holder = .loading
                let playlist = try await animeController.getPlaylist(id: id)
                holder = .success(Holder(series: nil, episodable: playlist))
            }catch let error {
                holder = .failure(error)
            }
        }else {
            do {
                holder = .loading
                let series = try await animeController.getSeries(id: id)
                let season = try await animeController.getSeason(id: series.seasons![selectedSeasonIndex].id)
                holder = .success(Holder(series: series, episodable: season))
            }catch let error {
                holder = .failure(error)
            }
        }
        
        do {
            if case .success(let data) = holder {
                let _ = try await ImageCache.shared.getImageData(url: data.episodable.posterUrl)
            }
        }catch let error {
            print("Cannot precache image: \(error)")
        }
    }
    
    private func loadMoreData() async {
        do {
            guard case .success(data: var data) = holder else {
                return
            }
            
            guard let paging = data.episodable.paging, paging.moreDataAvailable else {
                return
            }
            
            let additionalData = try await animeController.getSeason(id: data.episodable.id, lastSeen: paging.lastSeen)
            data.episodable = additionalData
            holder = .success(data)
        } catch let error {
            holder = .failure(error)
        }
    }
}

private struct Holder {
    let series: Series?
    var episodable: any Episodable
}

private class ScrollViewDelegate: NSObject, UIScrollViewDelegate {
    typealias Callback = (UIScrollView, CGFloat) -> Void
    
    var handler: Callback?
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollOffset = scrollView.contentOffset.y
        handler?(scrollView, scrollOffset)
    }
}
