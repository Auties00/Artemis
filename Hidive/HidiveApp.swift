//
//  HidiveApp.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import AVKit

@main
struct HidiveApp: App {
    private let connectivityController: ConnectivityController
    private let apiController: ApiController
    private let accountController: AccountController
    private let scheduleController: ScheduleController
    private let searchController: SearchController
    private let animeController: AnimeController
    private let libraryController: LibraryController
    @UIApplicationDelegateAdaptor(HidiveAppDelegate.self)
    private var appDelegate
    
    init() {
        UserDefaults.standard.register(defaults: [
            "simulcastsNotifications": true
        ])
        connectivityController = ConnectivityController()
        apiController = ApiController()
        animeController = AnimeController(apiController: apiController)
        accountController = AccountController(apiController: apiController, animeController: animeController)
        scheduleController = ScheduleController(apiController: apiController)
        searchController = SearchController(apiController: apiController)
        libraryController = LibraryController(apiController: apiController, animeController: animeController)
    }
    
    var body: some Scene {
        WindowGroup {
            HidiveContentView()
        }
        .environment(connectivityController)
        .environment(apiController)
        .environment(accountController)
        .environment(scheduleController)
        .environment(searchController)
        .environment(animeController)
        .environment(libraryController)
    }
}

class HidiveAppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return HidiveAppDelegate.orientationLock
    }
}
