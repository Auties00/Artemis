//
//  ProfileButtonView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI

struct ProfileButtonView: View {
    @ObservedObject
    private var accountController: AccountController
    @State
    private var isSheetOpened = false
    init(accountController: AccountController) {
        self.accountController = accountController
    }
    
    var body: some View {
        Button(
            action: {
                isSheetOpened.toggle()
            },
            label: {
                switch(accountController.account) {
                case .success(account: let account) where account.name != nil:
                    ProfileView(accountName: account.name!)
                default:
                    buildLoginButton()
                }
            }
        )
        .frame(width: 40, height: 40)
        .padding(.horizontal)
        .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
        .sheet(isPresented: $isSheetOpened, content: {
            if(accountController.isLoggedIn()) {
                AccountSheet {
                    print("Called")
                    isSheetOpened = false
                }
            }else {
                LoginSheet() {
                    isSheetOpened = false
                }
            }
        })
    }
    
    @ViewBuilder
    private func buildLoginButton() -> some View {
        Image(systemName: "person.crop.circle")
            .resizable()
            .frame(width: 32, height: 32)
    }
}
