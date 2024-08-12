//
//  HomeView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import ACarousel

struct HomeView: View {
    // The geometry reader reads a different height for List compared to ScrollView
    // In HomeView we use a ScrollView, as explained in the next comment,
    // So we can offset the view to make it the same when a full page info is shown
    private static let scrollViewFullHeightOffset: CGFloat = 23
    
    @Environment(AccountController.self) 
    private var accountController: AccountController
    
    var body: some View {
        TabNavigationView(title: "Home") {
            GeometryReader { geometry in
                // Can't use a list because there are nested horizontal scrollViews
                // .contextMenu has a problem with that where all the elements get grouped, probably an Apple bug
                // https://stackoverflow.com/questions/58583312/add-contextmenu-in-the-items-inside-of-a-list-in-swiftui
                ScrollView {
                    switch(accountController.dashboard) {
                    case .success(data: let data):
                        loadedBody(data: data, geometry: geometry)
                    case .empty, .loading:
                        ExpandedView(geometry: geometry, heightExtension: HomeView.scrollViewFullHeightOffset) {
                            LoadingView()
                        }
                    case .error(error: let error):
                        ExpandedView(geometry: geometry, heightExtension: HomeView.scrollViewFullHeightOffset) {
                            ErrorView(error: error)
                        }
                    }
                }
            }
            .refreshable {
                if(accountController.profile.value == nil) {
                    await accountController.login()
                }
                
                await accountController.loadDashboard()
            }
        }
    }
    
    @ViewBuilder
    private func loadedBody(data: DashboardResponse, geometry: GeometryProxy) -> some View {
        if(data.heroes.isEmpty && data.buckets.isEmpty) {
            ExpandedView(geometry: geometry, heightExtension: HomeView.scrollViewFullHeightOffset) {
                ErrorView(
                    title: "Unsupported region",
                    description: "Please log in to use HIDIVE in your region",
                    systemImage: "globe"
                )
            }
        }else {
            HeroCarouselView(heroes: data.heroes)
            
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(data.buckets) { bucket in
                    BucketSectionView(bucket: bucket)
                }
            }
        }
    }
}
