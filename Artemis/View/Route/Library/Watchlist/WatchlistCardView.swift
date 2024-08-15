//
//  WatchlistCardView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 06/08/24.
//

import SwiftUI

struct WatchlistCardView: View {
    private let watchlist: Watchlist
    init(watchlist: Watchlist) {
        self.watchlist = watchlist
    }
    
    var body: some View {
        HStack(alignment: .top) {
            if let thumbnailUrl = watchlist.thumbnails.first {
                NetworkImage(
                    thumbnailEntry: thumbnailUrl,
                    width: 175,
                    height: 100
                )
            } else {
                Image(systemName: "camera.metering.unknown")
                    .frame(width: 175, height: 100)
                    .background(Material.thin)
                    .cornerRadius(8)
            }
            
            Spacer()
                .frame(width: 12)
            
            VStack(alignment: .leading) {
                Text(watchlist.name)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .lineLimit(4)
                
                Text("Created by \(watchlist.ownership == "OWNED" ? "you" : "???")")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}
