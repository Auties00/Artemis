//
//  NotificationsSection.swift
//   Artemis
//
//  Created by Alessandro Autiero on 04/08/24.
//

import SwiftUI

struct NotificationsSection: View {
    @Environment(ScheduleController.self)
    private var scheduleController: ScheduleController
    
    var body: some View {
        List {
            Toggle("Schedule (Not Ready)", isOn: Binding(
                get: {
                    scheduleController.notifications
                },
                set: {
                    scheduleController.notifications = $0
                }
            ))
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
