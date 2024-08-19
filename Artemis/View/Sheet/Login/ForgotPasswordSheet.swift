//
//  LoginSheet.swift
//   Artemis
//
//  Created by Alessandro Autiero on 03/08/24.
//

import SwiftUI

struct ForgotPasswordSheet: View {
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(ScheduleController.self)
    private var scheduleController: ScheduleController
    
    @State
    private var email: String = ""
    
    @FocusState
    private var focused: Bool
    
    @State
    private var loading: Bool = false
    
    @State
    private var sent: Bool = false
    
    @State
    private var error: Bool = false
    
    @Environment(\.dismiss)
    private var goBack
    
    private let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Forgotten password?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHeading(.h1)
                    .padding(.horizontal, 15 + horizontalPaddingAddend)
                
                Text("Enter the email address you use with your account and we will send you a link to reset your password")
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 15 + horizontalPaddingAddend)
                    .padding(.top, 1)
                
                Form {
                    Section {
                        TextField("Email", text: $email)
                            .focused($focused)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .multilineTextAlignment(.leading)
                    }
                }
                .onSubmit {
                    resetPassword(userClick: false)
                }
                
                
                Button(
                    action: {
                        resetPassword(userClick: true)
                    },
                    label: {
                        if(loading) {
                            VStack {
                                ProgressView()
                                    .frame(width: 36, height: 36)
                            }.frame(maxWidth: .infinity, maxHeight: 36)
                        } else {
                            Text("Send link")
                                .frame(maxWidth: .infinity, maxHeight: 36)
                        }
                    }
                )
                .buttonStyle(.borderedProminent)
                .disabled(loading)
                .padding(.horizontal, 15 + horizontalPaddingAddend)
                .padding(.bottom, 60)
            }
            .navigationBarTitle("")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ExitButtonView() {
                        goBack()
                    }
                }
            })
        }
        .onAppear {
            focused = true
        }
        .alert(
            "Password reset error",
            isPresented: $error,
            actions: {},
            message: {
                Text("Cannot send link: please try again")
            }
        )
        .alert(
            "Link sent",
            isPresented: $sent,
            actions: {
                Button("OK", role: .cancel) {
                    goBack()
                }
            },
            message: {
                Text("The link to reset your password was successfully sent to \(email)")
            }
        )
    }
    
    private func resetPassword(userClick: Bool) {
        if(loading) {
            return
        }
        
        if(!userClick && email.isEmpty) {
            return
        }
        
        self.loading = true
        Task {
            defer {
                self.loading = false
            }
            
            do {
                try await accountController.resetPassword(email: email)
                self.sent = true
            } catch {
                self.error = true
            }
        }
    }
}
