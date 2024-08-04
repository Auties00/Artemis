//
//  DownloadsView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 20/07/24.
//

import SwiftUI

struct DownloadsView: View {
    var body: some View {
        List {
            Text("Downloads")
        }.navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DownloadsView()
}
