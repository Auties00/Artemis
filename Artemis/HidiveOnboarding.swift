//
//  HidiveOnboarding.swift
//  Hidive
//
//  Created by Alessandro Autiero on 26/07/24.
//

import Foundation
import SwiftUI
import WelcomeSheet

private let pages = [
    WelcomeSheetPage(
        title: "Welcome to\n HIDIVE",
        rows: [
            WelcomeSheetPageRow(
                imageSystemName: "rectangle.stack",
                accentColor: Color.blue,
                title: "Dive in!",
                content: "Watch anime from current to classics, plans starting at $5.99/MONTH"
            ),
            
            WelcomeSheetPageRow(
                imageSystemName: "star",
                accentColor: Color.blue,
                title: "Simulcasts",
                content: "Watch the latest series fresh from Japan with our seasonal simulcast anime lineup"
            ),
            
            WelcomeSheetPageRow(
                imageSystemName: "bookmark",
                accentColor: Color.blue,
                title: "Bookmarks",
                content: "Save your favourite anime so you can easily find it when you are ready to watch"
            ),
            
            WelcomeSheetPageRow(
                imageSystemName: "square.and.arrow.down.on.square",
                accentColor: Color.blue,
                title: "Offline play",
                content: "Download your favorite anime so you can watch even without a connection"
            )
        ],
        accentColor: Color.blue
    )
]

public extension View {
    @ViewBuilder
    func onboardingSheet(shouldPresent: Binding<Bool>, isPresented showSheet: Binding<Bool>, preferredColorScheme: ColorScheme) -> some View {
        if(shouldPresent.wrappedValue) {
            self.welcomeSheet(isPresented: showSheet, preferredColorScheme: preferredColorScheme, pages: pages).onAppear {
                if(shouldPresent.wrappedValue) {
                    shouldPresent.wrappedValue.toggle()
                    showSheet.wrappedValue.toggle()
                }
            }
        }else {
            self
        }
    }
}
