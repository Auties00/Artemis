//
//  LoginSheet.swift
//  Hidive
//
//  Created by Alessandro Autiero on 17/07/24.
//

import SwiftUI

struct AccountSheet: View {
    static let defaultUserName: String = "User"
    
    private let profile: Profile
    
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(ScheduleController.self)
    private var scheduleController: ScheduleController
    
    @Environment(SearchController.self)
    private var searchController: SearchController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @State
    private var displayName: String
    
    @Environment(\.openURL)
    private var openURL
    
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme
    
    private let onDismiss: () -> Void
    init(profile: Profile, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        self.profile = profile
        self._displayName = State(initialValue: profile.displayName)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Active Profile")) {
                    NavigationLink(
                        destination: ProfileSection(
                            profile: profile,
                            fresh: false,
                            onDismiss: onDismiss
                        ),
                        label: {
                            HStack(spacing: 0) {
                                ProfileView(accountName: displayName)
                                    .frame(width: 48, height: 48)
                                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(displayName)
                                        .font(.title2)
                                    Text("View Profile")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
                        }
                    )
                }
                
                Section(header: Text("General")) {
                    NavigationLink(
                        destination: AccountInformationSection(),
                        label: {
                            Text("Information")
                        }
                    )
                    NavigationLink(
                        destination: NotificationsSection(),
                        label: {
                            Text("Notifications")
                        }
                    )
                }
                
                
                Section(header: Text("Links")) {
                    Button(
                        action: {
                            openURL(URL(string: "https://www.sentaifilmworks.com/")!)
                        },
                        label: {
                            HStack {
                                Text("Shop")
                                Spacer()
                                NavigationLink.empty
                            }
                        }
                    )
                    .accentColor(colorScheme == .dark ? .white : .black)
                    
                    Button(
                        action: {
                            openURL(URL(string: "https://support.hidive.com/en/support/home")!)
                        },
                        label: {
                            HStack {
                                Text("Help")
                                Spacer()
                                NavigationLink.empty
                            }
                        }
                    )
                    .accentColor(colorScheme == .dark ? .white : .black)
                }
                
                Section(header: Text("Management")) {
                    NavigationLink(
                        destination: {
                            SelectProfileSection(
                                selectedProfile: profile,
                                onDismiss: onDismiss
                            )
                        },
                        label: {
                            Text("Switch profile")
                                .foregroundColor(.accentColor)
                        }
                    )
                    
                    Button(
                        action: {
                            onDismiss()
                            Task {
                                await accountController.logout()
                                await animeController.clearCache()
                                await accountController.loadDashboard()
                                await scheduleController.loadData()
                                await libraryController.loadWatchlists()
                                await libraryController.loadWatchHistory(reset: true)
                            }
                        },
                        label: {
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    )
                }
            }
            .navigationBarTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(.keyboard)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ExitButtonView() {
                        onDismiss()
                    }
                }
            })
            .onAppear {
                self.displayName = profile.displayName
            }
        }
    }
}

private extension NavigationLink where Label == EmptyView, Destination == EmptyView {
    static var empty: NavigationLink {
        self.init(destination: EmptyView(), label: { EmptyView() })
    }
 }
