//
//  NetworkImage.swift
//  Hidive
//
//  Created by Alessandro Autiero on 17/07/24.
//

import SwiftUI

struct NetworkImage: View {
    private let url: URL?
    private let cornerRadius: CGFloat
    private let fill: Bool
    @Environment(ConnectivityController.self)
    private var connectivityController: ConnectivityController
    @State
    private var data: AsyncResult<Data>
    init(url: String?, cornerRadius: CGFloat = 8, fill: Bool = false) {
        self.url = if let url = url {
            URL(string: url)
        }else {
            nil
        }
        self.cornerRadius = cornerRadius
        self.fill = fill
        self._data = State(initialValue: .empty)
    }
    
    init(thumbnailEntry: ThumbnailEntry?, cornerRadius: CGFloat = 8, fill: Bool = false) {
        self.url = switch(thumbnailEntry) {
        case .none:
            nil
        case .url(let url):
            URL(string: url)
        case .data:
            nil
        }
        self.cornerRadius = cornerRadius
        self.fill = fill
        let initialValue: AsyncResult<Data> = if case .data(let data) = thumbnailEntry {
            .success(data)
        } else {
            .empty
        }
        self._data = State(initialValue: initialValue)
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            switch(data) {
            case .success(data: let data):
                let result = resizableView(image: Image(uiImage: UIImage(data: data)!))
                if(cornerRadius > 0) {
                    result.cornerRadius(cornerRadius)
                }else {
                    result
                }
            case .error:
                error()
            default:
                if(!connectivityController.isConnected) {
                    error()
                }else {
                    ProgressView()
                }
            }
        }
        .task {
            await loadImage()
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
    private func error() -> some View {
        Rectangle()
            .cornerRadius(cornerRadius)
            .background(.thinMaterial)
        Image(systemName: connectivityController.isConnected ? "exclamationmark.triangle.fill" : "wifi.exclamationmark.circle.fill")
            .resizable()
            .frame(width: 30, height: 30)
    }
    
    @ViewBuilder
    private func resizableView(image: Image) -> some View {
        if(fill) {
            image
                .resizable()
                .scaledToFill()
        }else {
            image
                .resizable()
                .scaledToFit()
        }
    }
}
