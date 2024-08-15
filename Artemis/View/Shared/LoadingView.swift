//
//  LoadingView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(alignment: .center) {
            ProgressView()
            Text("LOADING...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color.clear)
        .id(UUID())
    }
}
