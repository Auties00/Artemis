//
//  LoginSheet.swift
//  Hidive
//
//  Created by Alessandro Autiero on 17/07/24.
//

import SwiftUI

struct AccountSheet: View {
    @EnvironmentObject
    private var accountController: AccountController
    
    private let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationStack {
            List {
                if case .success(account: let account) = accountController.account {
                    Section {
                        HStack(spacing: 0) {
                            ProfileView(accountName: account.name ?? account.email!)
                                .frame(width: 48, height: 48)
                                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text(account.name!)
                                    .font(.title2)
                                Text(account.email!)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }.padding(.horizontal)
                        }
                    }
                }
                
                Section {
                    Button(
                        action: {
                            Task {
                                await accountController.logout()
                            }
                        },
                        label: {
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    )
                }
            }.navigationBarTitle("Account")
                .navigationBarTitleDisplayMode(.inline)
                .ignoresSafeArea(.keyboard)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ExitButtonView() {
                            onDismiss()
                        }
                    }
                })
        }
    }
}
