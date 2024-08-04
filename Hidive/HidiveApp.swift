//
//  HidiveApp.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI

@main
struct HidiveApp: App {
    private let apiController: ApiController
    private let accountController: AccountController
    private let scheduleController: ScheduleController
    private let searchController: SearchController
    private let animeController: AnimeController
    init() {
        apiController = ApiController()
        accountController = AccountController(apiController: apiController)
        scheduleController = ScheduleController(apiController: apiController)
        searchController = SearchController()
        animeController = AnimeController(apiController: apiController)
    }
    
    var body: some Scene {
        WindowGroup {
            HidiveContentView()
        }
        .environmentObject(apiController)
        .environmentObject(accountController)
        .environmentObject(scheduleController)
        .environmentObject(searchController)
        .environmentObject(animeController)
    }
}
