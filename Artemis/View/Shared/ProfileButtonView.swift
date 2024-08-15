//
//  ProfileButtonView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import AlertToast

struct ProfileButtonView: View {
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    private let action: (Bool) -> Void
    init(action: @escaping (Bool) -> Void) {
        self.action = action
    }
    
    var body: some View {
        Button(
            action: {
                if(!accountController.isLoggedIn()) {
                    action(false)
                }else {
                    switch(accountController.profile) {
                    case .success(let profile):
                        action(profile != nil)
                    case .error:
                        action(false)
                    default:
                        break
                    }
                }
            },
            label: {
                if case .success(let profile) = accountController.profile, let profile = profile {
                    ProfileView(accountName: profile.displayName)
                } else {
                    loginButton()
                }
            }
        )
        .frame(width: 40, height: 40)
        .padding(.horizontal)
        .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
    }
    
    @ViewBuilder
    private func loginButton() -> some View {
        Image(systemName: "person.crop.circle")
            .resizable()
            .frame(width: 32, height: 32)
    }
}
