//
//  ScheduleView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject
    private var scheduleController: ScheduleController
    
    var body: some View {
        TabNavigationView(title: "Schedule") {
            GeometryReader { geometry in
                List {
                    switch(scheduleController.data) {
                    case .empty, .loading:
                        ExpandedView(geometry: geometry) {
                            LoadingView()
                        }
                    case .success(data: let data):
                        if(data.isEmpty) {
                            ExpandedView(geometry: geometry) {
                                InformationView(title: "No releases available", description: "Try again later")
                            }
                        } else {
                            ForEach(data) { entry in
                                ScheduleCardView(entry: entry)
                            }
                        }
                    case .failure(error: let error):
                        ExpandedView(geometry: geometry) {
                            ErrorView(error: error)
                        }
                    }
                }
            }
        }.task {
            await scheduleController.loadData()
        }
    }
}
