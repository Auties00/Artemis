//
//  HomeView.swift
//   Artemis
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI

struct ScheduleView: View {
    private static let headerId: String = "scheduleHeader"
    
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(ScheduleController.self)
    private var scheduleController: ScheduleController
    
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme
    
    @State
    private var showSheet = false
    
    var body: some View {
        TabNavigationView(title: "Schedule") {
            GeometryReader { geometry in
                ScrollViewReader { scrollProxy in
                    List {
                        switch(scheduleController.data) {
                        case .success(data: let data):
                            loadedBody(data: data, geometry: geometry)                    .onAppear {
                                routerController.pathHandler = {
                                    withAnimation {
                                        scrollProxy.scrollTo(ScheduleView.headerId, anchor: .center)
                                    }
                                    return true
                                }
                            }
                        case .empty, .loading:
                            ExpandedView(geometry: geometry) {
                                LoadingView()
                            }
                        case .error(error: let error):
                            ExpandedView(geometry: geometry) {
                                ErrorView(error: error)
                            }
                        }
                    }
                    .animation(nil, value: UUID())
                }
            }
            .refreshable {
                if(accountController.profile.value == nil) {
                    await accountController.login()
                }
                
                await scheduleController.loadData()
            }
        }
    }
    
    @ViewBuilder
    private func loadedBody(data: [ScheduleEntry], geometry: GeometryProxy) -> some View {
        if(data.isEmpty) {
            ExpandedView(geometry: geometry) {
                ErrorView(
                    title: "No releases",
                    description: "No releases are scheduled for this week",
                    systemImage: "film.stack.fill"
                )
            }
        }else {
            ForEach(data) { scheduleEntry in
                ScheduleCardView(headerId: scheduleEntry == data.first ? ScheduleView.headerId : nil, entry: scheduleEntry) { addToWatchlistItem in
                    routerController.addToWatchlistItem = addToWatchlistItem
                }
            }
        }
    }
}
