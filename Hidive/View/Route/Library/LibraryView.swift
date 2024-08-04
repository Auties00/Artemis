//
//  LibraryView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI

struct LibraryView: View {
    var body: some View {
        TabNavigationView(title: "Library") {
            List {
                NavigationLink(value: PageType.library(.favourites)) {
                    HStack {
                        Image(systemName: "list.star")
                            .resizable()
                            .foregroundColor(.accentColor)
                            .frame(width: 20, height: 20)
                        Spacer()
                            .frame(width: 12)
                        Text("Watchlists")
                            .font(.title2)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                
                NavigationLink(value: PageType.library(.history)) {
                    HStack {
                        Image(systemName: "clock")
                            .resizable()
                            .foregroundColor(.accentColor)
                            .frame(width: 20, height: 20)
                        Spacer()
                            .frame(width: 12)
                        Text("History")
                            .font(.title2)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
                
                NavigationLink(value: PageType.library(.downloads)) {
                    HStack {
                        Image(systemName: "arrow.down")
                            .resizable()
                            .foregroundColor(.accentColor)
                            .frame(width: 20, height: 20)
                        Spacer()
                            .frame(width: 12)
                        Text("Downloads")
                            .font(.title2)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
            }
            .listRowSeparator(.visible)
            .scrollContentBackground(.hidden)
        }
    }
}
