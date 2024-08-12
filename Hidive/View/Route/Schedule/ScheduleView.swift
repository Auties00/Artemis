//
//  ScheduleView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import AlertToast

struct ScheduleView: View {
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(ScheduleController.self)
    private var scheduleController: ScheduleController
    
    @State
    private var addToWatchlistItem: DescriptableEntry?
    
    @State
    private var addedItemToWatchlist: Bool = false
    
    @State
    private var addItemToWatchlistError: Bool = false
    
    var body: some View {
        TabNavigationView(title: "Schedule") {
            GeometryReader { geometry in
                List {
                    switch(scheduleController.data) {
                    case .success(data: let data):
                        if(!data.isEmpty) {
                            ForEach(data) { entry in
                                ScheduleCardView(entry: entry) { addToWatchlistItem in
                                    if let addToWatchlistItem = addToWatchlistItem {
                                        self.addToWatchlistItem = addToWatchlistItem
                                    }else {
                                        self.addItemToWatchlistError = true
                                    }
                                }
                            }
                        }else {
                            ExpandedView(geometry: geometry) {
                                ErrorView(
                                    title: "No releases",
                                    description: "No releases are scheduled for this week",
                                    systemImage: "film.stack.fill"
                                )
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
            }
            .sheet(item: $addToWatchlistItem) { item in
                AddToWatchlistSheet(item: item) { addedItemToWatchlist in
                    addToWatchlistItem = nil
                    self.addedItemToWatchlist = addedItemToWatchlist
                }
            }
            .toast(isPresenting: $addedItemToWatchlist) {
                AlertToast(type: .complete(Color.green), title: "Added item to watchlist", subTitle: "Tap to dismiss")
            }
            .toast(isPresenting: $addItemToWatchlistError) {
                AlertToast(type: .error(Color.red), title: "Cannot add item to watchlist", subTitle: "Fetch error")
            }
            .refreshable {
                if(accountController.profile.value == nil) {
                    await accountController.login()
                }
                
                await scheduleController.loadData()
            }
        }
    }
}
