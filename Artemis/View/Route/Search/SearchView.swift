//
//  SearchView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 21/07/24.
//

import SwiftUI

struct SearchView: View {
    @Environment(SearchController.self)
    private var searchController: SearchController
    
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    @State
    private var searchText: String = ""
    
    @State
    private var searching: Bool = false
    
    @State
    private var results: AsyncResult<[SearchEntry]> = .empty
    
    @State
    private var task: Task<Void, Error>?
    
    var body: some View {
        TabNavigationView(title: "Search") {
            GeometryReader() { geometry in
                List {
                    switch(results) {
                    case .empty:
                        // Need this LazyVStack or the largeTitle will be initially collapsed
                        // No idea why it happens, but it doesn't happen with a ScrollView, could be a SwiftUI bug
                        LazyVStack {
                            ExpandedView(geometry: geometry) {
                                ContentUnavailableView(
                                    "Start searching",
                                    systemImage: "magnifyingglass",
                                    description: Text("The results of your query will appear here")
                                )
                            }
                        }
                        .listRowBackground(Color.clear)
                    case .loading:
                        ExpandedView(geometry: geometry) {
                            LoadingView()
                        }
                    case .success(let results):
                        if(results.isEmpty) {
                            ExpandedView(geometry: geometry) {
                                ContentUnavailableView.search(text: searchText)
                            }
                        }else {
                            ForEach(results) { result in
                                SearchEntryView(entry: result)
                            }
                        }
                    case .error(let error):
                        if(error.isCancelledRequestError) {
                            ExpandedView(geometry: geometry) {
                                LoadingView()
                            }
                        }else {
                            ExpandedView(geometry: geometry) {
                                ErrorView(error: error)
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .onAppear {
                    routerController.pathHandler = {
                        if(!searchText.isEmpty) {
                            searchText = ""
                            searching = false
                        }else {
                            searching.toggle()
                        }
                        
                        return true
                    }
                }
            }
            .searchable(text: $searchText, isPresented: $searching, placement: .navigationBarDrawer(displayMode: .always))
        }
        .onChange(of: searchText) { oldValue, newValue in
            task?.cancel()
            task = Task {
                do {
                    self.results = if let results = try await searchController.search(query: searchText) {
                        .success(results)
                    }else {
                        .empty
                    }
                }catch let error {
                    results = .error(error)
                }
            }
        }
    }
}
