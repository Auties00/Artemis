//
//  ContentView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import WelcomeSheet

struct HidiveContentView: View {
    @AppStorage("firstLaunch")
    private var firstLaunch = true
    @State
    private var showSheet = false
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme
    @Environment(AccountController.self)
    private var accountController: AccountController
    @Environment(ScheduleController.self)
    private var scheduleController: ScheduleController
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    @Environment(SearchController.self)
    private var searchController: SearchController
    
    var body: some View {
        NavigationView {
            let result = TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(RootPageType.home)
                ScheduleView()
                    .tabItem {
                        Label("Schedule", systemImage: "calendar")
                    }
                    .tag(RootPageType.schedule)
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "rectangle.stack")
                    }
                    .tag(RootPageType.library)
                SearchView()
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(RootPageType.search)
            }
            if(!firstLaunch) {
                result
            }else {
                result.onboardingSheet(shouldPresent: $firstLaunch, isPresented: $showSheet, preferredColorScheme: colorScheme)
            }
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
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            HidiveAppDelegate.orientationLock = .portrait
        }.onDisappear {
            HidiveAppDelegate.orientationLock = .all
        }
    }
}
