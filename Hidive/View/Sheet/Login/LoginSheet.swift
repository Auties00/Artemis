//
//  LoginSheet.swift
//  Hidive
//
//  Created by Alessandro Autiero on 11/07/24.
//

import SwiftUI

struct LoginSheet: View {
    @State
    private var email: String = ""
    
    @State
    private var password: String = ""
    
    @State
    private var loading: Bool = false
    
    @EnvironmentObject
    private var accountController: AccountController
    
    private let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("HIDIVE")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHeading(.h1)
                    .padding(.horizontal, 15 + iPhoneDimensions.horizontalPaddingAddend)
                
                Text("Sign in with an email or create a new account to start watching our anime catalog and exclusive simulcasts")
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 15 + iPhoneDimensions.horizontalPaddingAddend)
                    .padding(.top, 1)
                
                Form {
                    Section {
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.password)
                            .multilineTextAlignment(.leading)
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .multilineTextAlignment(.leading)
                    }
                    Button(
                        action: {
                            
                        },
                        label: {
                            Text("Forgot password?")
                        }
                    )
                }.onSubmit(login)
                
                
                Button(
                    action: {
                        
                    },
                    label: {
                        Text("Register a new account")
                    }
                ).padding(.vertical)
                
                Button(
                    action: login,
                    label: {
                        if(loading) {
                            VStack {
                                ProgressView()
                                    .frame(width: 36, height: 36)
                            }.frame(maxWidth: .infinity, maxHeight: 36)
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity, maxHeight: 36)
                        }
                    }
                ).buttonStyle(.borderedProminent)
                    .disabled(loading)
                    .padding(.horizontal, 15 + iPhoneDimensions.horizontalPaddingAddend)
                    .padding(.bottom, 60)
            }.navigationBarTitle("")
                .ignoresSafeArea(.keyboard)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ExitButtonView() {
                            onDismiss()
                        }
                    }
                })
                //.errorAlert(error: $accountController.account.error)
        }
    }
    
    private func login() {
        if(loading) {
            return
        }
        
        self.loading = true
        Task {
            defer {
                self.loading = false
            }
            
            let request = LoginRequest(id: email, secret: password)
            await accountController.loginUser(payload: request)
            onDismiss()
        }
    }
}

private extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        let localizedAlertError = LocalizedErrorWrapper(error: error.wrappedValue)
        return alert(isPresented: .constant(true), error: localizedAlertError) { _ in
            Button("Close") {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
}
