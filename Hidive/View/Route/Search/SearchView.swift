//
//  SearchView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject
    private var searchController: SearchController
    
    var body: some View {
        TabNavigationView(title: "Search", searchQuery: $searchController.query) {
            GeometryReader() { geometry in
                List {
                    switch(searchController.results) {
                    case .empty:
                        VStack {
                            
                        }
                    case .loading:
                        ExpandedView(geometry: geometry) {
                            LoadingView()
                        }
                    case .success(data: let results):
                        ForEach(results) { result in
                            SearchEntryView(entry: result)
                        }
                    case .failure(error: let error):
                        ExpandedView(geometry: geometry) {
                            ErrorView(error: error)
                        }
                    }
                }
            }.task {
                await searchController.executeSearch()
            }
        }
    }
}
