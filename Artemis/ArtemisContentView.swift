//
//  ContentView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import WelcomeSheet

struct ArtemisContentView: View {
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(ScheduleController.self)
    private var scheduleController: ScheduleController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(SearchController.self)
    private var searchController: SearchController
    
    @State
    private var selectedTab: RootPageType? = .home
    
    private let routers: [RootPageType: RouterController] = Dictionary(uniqueKeysWithValues: RootPageType.allCases.map { ($0, RouterController()) })
    
    var body: some View {
        if(UIDevice.current.userInterfaceIdiom == .pad) {
            NavigationSplitView {
                List(RootPageType.allCases, id: \.self, selection: $selectedTab) { pageType in
                    switch(pageType) {
                    case .home:
                        Label("Home", systemImage: "house")
                    case .schedule:
                        Label("Schedule", systemImage: "calendar")
                    case .library:
                        Label("Library", systemImage: "rectangle.stack")
                    case .search:
                        Label("Search", systemImage: "magnifyingglass")
                    }
                }
                .navigationTitle("Artemis")
            } detail: {
                switch(selectedTab ?? .home) {
                case .home:
                    HomeView()
                        .environment(routers[.home])
                case .schedule:
                    ScheduleView()
                        .environment(routers[.schedule])
                case .library:
                    LibraryView()
                        .environment(routers[.library])
                case .search:
                   SearchView()
                        .environment(routers[.search])
                }
            }
            .task {
              await loadData()
            }
        }else {
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
              await loadData()
            }
            .onAppear {
                let _ = self.onAppear()
            }.onDisappear {
                let _ = self.onDisappear()
            }
        }
    }
    
    private func loadData() async {
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
    
    private func createTabIndexBinding() -> Binding<RootPageType> {
        return Binding(
            get: {
                selectedTab ?? .home
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
        ArtemisAppDelegate.orientationLock = .portrait
    }
}
