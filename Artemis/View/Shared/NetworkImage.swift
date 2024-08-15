//
//  NetworkImage.swift
//  Hidive
//
//  Created by Alessandro Autiero on 17/07/24.
//

import SwiftUI

struct NetworkImage<Overlay>: View where Overlay: View {
    @Environment(ConnectivityController.self)
    private var connectivityController: ConnectivityController
    
    @State
    private var data: AsyncResult<Data>
    
    private let url: URL?
    private let width: CGFloat
    private let height: CGFloat
    private let cornerRadius: CGFloat
    private let overlay: () -> Overlay
    init(url: String?, width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 8, @ViewBuilder overlay: @escaping () -> Overlay = { EmptyView() }) {
        self.url = if let url = url {
            URL(string: url)
        }else {
            nil
        }
        self.cornerRadius = cornerRadius
        self._data = State(initialValue: .empty)
        self.width = width
        self.height = height
        self.overlay = overlay
    }
    
    init(thumbnailEntry: ThumbnailEntry?, width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 8, @ViewBuilder overlay: @escaping () -> Overlay = { EmptyView() }) {
        self.url = switch(thumbnailEntry) {
        case .none:
            nil
        case .url(let url):
            URL(string: url)
        case .data:
            nil
        }
        self.cornerRadius = cornerRadius
        let initialValue: AsyncResult<Data> = if case .data(let data) = thumbnailEntry {
            .success(data)
        } else {
            .empty
        }
        self._data = State(initialValue: initialValue)
        self.width = width
        self.height = height
        self.overlay = overlay
    }
    
    var body: some View {
        switch(data) {
        case .success(data: let data):
            loaded(data: data)
        case .error:
            error()
        default:
           loading()        .task {
               await loadImage()
           }
        }
    }
    
    private func loadImage() async {
        if case .empty = data {
            do {
                data = .loading
                guard let result = try await ImageCache.shared.getImageData(url: url) else {
                    throw RequestError.invalidResponseData()
                }
                
                data = .success(result)
            }catch let error {
                data = .error(error)
            }
        }
    }
    
    @ViewBuilder
    private func loaded(data: Data) -> some View {
        if(width == .infinity) {
            Image(uiImage: UIImage(data: data)!)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: width, minHeight: height, maxHeight: height)
                .overlay(alignment: .bottom, content: overlay)
                .cornerRadius(cornerRadius)
        }else {
            Image(uiImage: UIImage(data: data)!)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .overlay(alignment: .bottom, content: overlay)
                .cornerRadius(cornerRadius)
        }
    }
    
    @ViewBuilder
    private func loading() -> some View {
        if(!connectivityController.isConnected) {
            error()
        }else {
            if(width == .infinity) {
                ProgressView()
                    .frame(maxWidth: width, minHeight: height)
            }else {
                ProgressView()
                    .frame(width: width, height: height)
            }
        }
    }
    
    @ViewBuilder
    private func error() -> some View {
        let result = ZStack {
            Rectangle()
                .cornerRadius(cornerRadius)
                .background(.thinMaterial)
            Image(systemName: connectivityController.isConnected ? "exclamationmark.triangle.fill" : "wifi.exclamationmark.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
        }
        if(width == .infinity) {
            result
                .frame(maxWidth: width, minHeight: height)
        }else {
            result
                .frame(width: width, height: height)
        }
    }
}
