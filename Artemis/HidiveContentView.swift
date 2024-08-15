//
//  ContentView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import WelcomeSheet

struct HidiveContentView: View {
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(ScheduleController.self)
    private var scheduleController: ScheduleController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(SearchController.self)
    private var searchController: SearchController
    
    @State
    private var selectedTab: RootPageType = .home
    
    private let routers: [RootPageType: RouterController] = Dictionary(uniqueKeysWithValues: RootPageType.allCases.map { ($0, RouterController()) })
    
    var body: some View {
        TabView(selection: createTabIndexBinding()) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .environment(routers[.home])
                .tag(RootPageType.home)
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .environment(routers[.schedule])
                .tag(RootPageType.schedule)
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "rectangle.stack")
                }
                .environment(routers[.library])
                .tag(RootPageType.library)
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .environment(routers[.search])
                .tag(RootPageType.search)
        }
        .task {
            if case .empty = accountController.profile {
                await accountController.login()
            }
            
            if case .empty = accountController.dashboard {
                await accountController.loadDashboard()
            }
            
            if case .empty = scheduleController.data {
                await scheduleController.loadData()
            }
            
            if case .empty = libraryController.watchlists {
                await libraryController.loadWatchlists()
            }
            
            if case .empty = libraryController.watchHistory {
                await libraryController.loadWatchHistory()
            }
        }
        .onAppear {
            let _ = self.onAppear()
        }.onDisappear {
            let _ = self.onDisappear()
        }
    }
    
    private func createTabIndexBinding() -> Binding<RootPageType> {
        return Binding(
            get: {
                selectedTab
            },
            set: {
                guard $0 == selectedTab else {
                    selectedTab = $0
                    return
                }
                
                guard let router = routers[$0] else {
                    return
                }
                
                if(router.pathHandler()) {
                    return
                }
                
                navigateBack(router: router)
            }
        )
    }
    
    private func navigateBack(router: RouterController) {
        var path = router.path
        if(!path.isEmpty) {
            path.removeLast()
            router.path = path
        }
    }
    
    @available(tvOS, unavailable)
    private func onAppear() {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        HidiveAppDelegate.orientationLock = .portrait
    }
    
    @available(tvOS, unavailable)
    private func onDisappear() {
        HidiveAppDelegate.orientationLock = .all
    }
}
