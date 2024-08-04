//
//  SearchEntryView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import SwiftUI

struct SearchEntryView: View {
    private let entry: SearchEntry
    init(entry: SearchEntry) {
        self.entry = entry
    }
    
    var body: some View {
        NavigationLink(value: PageType.search(entry)) {
            HStack(alignment: .top, spacing: 0) {
                NetworkImage(url: entry.coverUrl)
                    .frame(width: 175, height: 100)
                Spacer()
                    .frame(width: 12)
                Text(entry.name)
                    .lineLimit(2)
                    .font(.system(size: 24))
                    .fontWeight(.bold)
            }
        }.buttonStyle(PlainButtonStyle())
    }
}
