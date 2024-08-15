//
//  ErrorView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import SwiftUI

struct ErrorView: View {
    @Environment(RouterController.self)
    private var routerController: RouterController
    
    private let title: String
    private let description: String
    private let systemImage: String
    private let showDownloads: Bool
    init(error: Error) {
        if(error.isNoConnectionError) {
            self.init(
                title: "No Internet Connection",
                description: "Please check your connection and try again",
                systemImage: "wifi.exclamationmark",
                showDownloads: true
            )
        }else {
            let localizedError = LocalizedErrorWrapper(error: error)
            let title = localizedError.recoverySuggestion == nil ? "Unknown error" : localizedError.localizedDescription
            let description = if let recoverySuggestion = localizedError.recoverySuggestion {
                recoverySuggestion
            }else {
                localizedError.localizedDescription
            }
            self.init(
                title: title,
                description: description
            )
        }
    }
    
    init(title: String, description: String, systemImage: String = "exclamationmark.triangle.fill", showDownloads: Bool = false) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.showDownloads = showDownloads
    }
    
    var body: some View {
        ContentUnavailableView(
            label: {
                Label(
                    title,
                    systemImage: systemImage
                )
            },
            description: {
                Text(description)
            },
            actions: {
                if(showDownloads) {
                    Button("Show Downloads") {
                        routerController.path.append(NestedPageType.library(.downloads))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        )
    }
}
