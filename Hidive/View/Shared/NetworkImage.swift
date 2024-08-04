//
//  NetworkImage.swift
//  Hidive
//
//  Created by Alessandro Autiero on 17/07/24.
//

import SwiftUI
import CachedAsyncImage

struct NetworkImage: View {
    private let url: String
    @State
    private var data: AsyncResult<Data>
    init(url: String) {
        self.url = url
        self.data = .empty
    }
    
    var body: some View {
        VStack {
            switch(data) {
            case .empty, .loading:
                ProgressView()
            case .success(data: let data):
                Image(uiImage: UIImage(data: data)!)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(6)
            case .failure(error: let error):
                ErrorView(error: error)
            }
        }.task {
            do {
                data = .loading
                guard let url = URL(string: url) else {
                    throw RequestError.invalidUrl
                }
                
                let request = URLRequest(url: url)
                let (responseData, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if(httpResponse.statusCode != 200) {
                        throw RequestError.invalidResponseData()
                    }
                }
                data = .success(responseData)
            }catch let error {
                data = .failure(error)
            }
        }
    }
    
    @ViewBuilder
    private func buildImage() -> some View {
    
    }
}
