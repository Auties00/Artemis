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
    private static let headerId: String = "homeHeader"
    private static let contentId: String = "homeContent"
    
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme
    
    @AppStorage("firstLaunch")
    private var firstLaunch = true
    
    @State
    private var showSheet = false
    
    @State
    private var scrollPosition: String?
    
    var body: some View {
        TabNavigationView(title: "Home") {
            GeometryReader { geometry in
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack {
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
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: $scrollPosition)
                    .onAppear {
                        routerController.pathHandler = {
                            withAnimation {
                                scrollProxy.scrollTo(HomeView.headerId, anchor: .top)
                            }
                            return true
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
        .onboardingSheet(shouldPresent: $firstLaunch, isPresented: $showSheet, preferredColorScheme: colorScheme)
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
                .id(HomeView.headerId)
            
            ForEach(data.buckets) { bucket in
                BucketSectionView(bucket: bucket)
            }
            .id(HomeView.contentId)
        }
    }
}
