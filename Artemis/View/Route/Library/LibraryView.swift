//
//  LibraryView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI

struct LibraryView: View {
    var body: some View {
        TabNavigationView(title: "Library") {
            List {
                item(destination: .watchlists, icon: "list.star", label: "Watchlists")

                item(destination: .history, icon: "clock", label: "History")

                item(destination: .downloads, icon: "arrow.down", label: "Downloads")
                
                // Used to make the previous item's separator visible
                Spacer()
                    .frame(width: 0, height: 0)
                    .listRowBackground(Color.clear)
            }
            .listRowSeparator(.visible)
        }
    }
    
    @ViewBuilder
    private func item(destination: LibraryPageType, icon: String, label: String) -> some View {
        NavigationLink(value: NestedPageType.librarySection(destination)) {
            HStack {
                Image(systemName: icon)
                    .resizable()
                    .foregroundColor(.accentColor)
                    .frame(width: 22, height: 22)
                Spacer()
                    .frame(width: 16)
                Text(label)
                    .font(.title2)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .padding(.trailing)
    }
}
