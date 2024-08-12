//
//  LoginSheet.swift
//  Hidive
//
//  Created by Alessandro Autiero on 11/07/24.
//

import SwiftUI

struct LoginSheet: View {
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(ScheduleController.self)
    private var scheduleController: ScheduleController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @State
    private var email: String = ""
    
    @State
    private var password: String = ""
    
    @State
    private var confirmPassword: String = ""
    
    @State
    private var registering: Bool = false
    
    @State
    private var loading: Bool = false

    @State
    private var error: Bool = false
    
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
                    .padding(.horizontal, 15 + horizontalPaddingAddend)
                
                Text("Sign in with an email or create a new account to start watching our anime catalog and exclusive simulcasts")
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 15 + horizontalPaddingAddend)
                    .padding(.top, 1)
                
                Form {
                    Section {
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.username)
                            .multilineTextAlignment(.leading)
                        SecureField("Password", text: $password)
                            .textContentType(registering ? .newPassword : .password)
                            .multilineTextAlignment(.leading)
                        if(registering) {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    if(!registering) {
                        NavigationLink(
                            destination: ForgotPasswordSheet(onDismiss: onDismiss),
                            label: {
                                Text("Forgot password?")
                                    .foregroundColor(.accentColor)
                            }
                        )
                    }
                }
                .onSubmit {
                    execute(userClick: false)
                }
                
                
                Button(
                    action: {
                        if(!loading) {
                            registering.toggle()
                        }
                    },
                    label: {
                        if(registering) {
                            Text("Sign into an existing account")
                        }else {
                            Text("Register a new account")
                        }
                    }
                )
                .disabled(loading)
                .padding(.vertical)
                
                Button(
                    action: {
                        execute(userClick: true)
                    },
                    label: {
                        if(loading) {
                            VStack {
                                ProgressView()
                                    .frame(width: 36, height: 36)
                            }.frame(maxWidth: .infinity, maxHeight: 36)
                        } else {
                            Text(registering ? "Sign up" : "Sign In")
                                .frame(maxWidth: .infinity, maxHeight: 36)
                        }
                    }
                )
                .buttonStyle(.borderedProminent)
                .disabled(loading)
                .padding(.horizontal, 15 + horizontalPaddingAddend)
                .padding(.bottom, 60)
            }
            .ignoresSafeArea(.keyboard)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ExitButtonView() {
                        onDismiss()
                    }
                }
            })
        }
        .alert(
            registering ? "Registration error" : "Login error",
            isPresented: $error,
            actions: {},
            message: {
                Text(accountController.profile.error?.localizedDescription ?? "Unknown error")
            }
        )
    }
    
    private func execute(userClick: Bool) {
        if(loading) {
            return
        }
        
        if(!userClick && (email.isEmpty || password.isEmpty)) {
            return
        }
        
        if(registering && password != confirmPassword) {
            error = true
            accountController.profile = .error(RegisterError.invalidCode(code: "CONFIRM_PASSWORD"))
            return
        }
        
        self.loading = true
        Task {
            defer {
                self.loading = false
            }
            
            let result = registering ? await accountController.register(email: email, password: password, tracking: true) : await accountController.loginUser(email: email, password: password)
            if(!result) {
                self.error = true
                return
            }
            
            onDismiss()
            if(!registering) {
                await accountController.loadDashboard()
                await animeController.clearCache()
                await scheduleController.loadData()
                await libraryController.loadWatchlists()
                await libraryController.loadWatchHistory(reset: true)
            }
        }
    }
}
