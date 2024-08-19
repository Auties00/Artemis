//
//  LoadingMoreView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 05/08/24.
//

import SwiftUI

struct LoadingMoreView: View {
    private let loader: () async -> Void
    init(loader: @escaping () async -> Void) {
        self.loader = loader
    }
    
    var body: some View {
        VStack(alignment: .center) {
            ProgressView()
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom)
        .listRowBackground(Color.clear)
        .task {
            await loader()
        }
        .id(UUID())
    }
}
