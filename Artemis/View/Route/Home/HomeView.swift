//
//  HomeView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import ACarousel
import SwiftUIIntrospect

struct HomeView: View {
    // The geometry reader reads a different height for List compared to ScrollView
    // In HomeView we use a ScrollView, as explained in the next comment,
    // So we can offset the view to make it the same when a full page info is shown
    private static let scrollViewFullHeightOffset: CGFloat = 23
    
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
    
    // We can't use a List because that treats nested horizontal scrollViews as single objects, so contextMenu doesn't work as intended
    // If we use ScrollView, then we can't scroll to the top because there of a bug in SwiftUI
    // So introspection is all we can use
    @State
    private var scrollView: UIScrollView?
    
    // Avoid any magic values or calculation as initialy the largeTitle is always shown (app doesn't support landscape mode from iPhone)
    @State
    private var initialContentOffset: CGFloat?
    
    var body: some View {
        TabNavigationView(title: "Home") {
            let result = GeometryReader { geometry in
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        switch(accountController.dashboard) {
                        case .success(data: let data):
                            loadedBody(data: data, geometry: geometry)
                                .onAppear {
                                    calculateTopScrollOffset(geometry: geometry)
                                    routerController.pathHandler = {
                                        guard let scrollView = scrollView else {
                                            return false
                                        }
                                        
                                        scrollView.setContentOffset(CGPoint(x: 0, y: -initialContentOffset!), animated: true)
                                        return true
                                    }
                                }
                        case .empty, .loading:
                            ExpandedView(geometry: geometry, heightExtension: HomeView.scrollViewFullHeightOffset) {
                                LoadingView()
                                    .onAppear {
                                    calculateTopScrollOffset(geometry: geometry)
                                }
                            }
                        case .error(error: let error):
                            ExpandedView(geometry: geometry, heightExtension: HomeView.scrollViewFullHeightOffset) {
                                ErrorView(error: error)
                                    .onAppear {
                                        calculateTopScrollOffset(geometry: geometry)
                                    }
                            }
                        }
                    }
                    .introspect(.scrollView, on: .iOS(.v17, .v18)) { scrollView in
                        self.scrollView = scrollView
                    }
                }
            }
                .refreshable {
                    if(accountController.profile.value == nil) {
                        await accountController.login()
                    }
                    
                    await accountController.loadDashboard()
                }
            if(UIDevice.current.userInterfaceIdiom == .pad) {
                result
                    .ignoresSafeArea(.all, edges: [.top, .leading, .trailing])
            }else {
                result
            }
        }
        .onboardingSheet(shouldPresent: $firstLaunch, isPresented: $showSheet, preferredColorScheme: colorScheme)
    }
    
    private func calculateTopScrollOffset(geometry: GeometryProxy) {
        let newValue = geometry.safeAreaInsets.top
        if(initialContentOffset == nil || (initialContentOffset ?? 0) < newValue) {
            initialContentOffset = newValue
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
            if(UIDevice.current.userInterfaceIdiom == .pad) {
                HeroHeaderView(heroes: data.heroes)
            }else {
                HeroCarouselView(heroes: data.heroes)
            }
            
            LazyVStack {
                ForEach(data.buckets) { bucket in
                    BucketSectionView(bucket: bucket)
                }
            }
        }
    }
}
