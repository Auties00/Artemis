//
//  SelectProfileSection.swift
//   Artemis
//
//  Created by Alessandro Autiero on 11/08/24.
//

import SwiftUI
import AlertToast

struct SelectProfileSection: View {
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(ScheduleController.self)
    private var scheduleController: ScheduleController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme
    
    @State
    private var profiles: AsyncResult<[Profile]> = .empty
    
    private let selectedProfile: Profile
    private let onDismiss: () -> Void
    init(selectedProfile: Profile, onDismiss: @escaping () -> Void) {
        self.selectedProfile = selectedProfile
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                switch(profiles) {
                case .empty, .loading:
                    ExpandedView(geometry: geometry) {
                        LoadingView()
                    }
                case .success(let profiles):
                    loadedBody(profiles: profiles)
                case .error(let error):
                    ExpandedView(geometry: geometry) {
                        ErrorView(error: error)
                    }
                }
            }
            .listRowSpacing(12)
        }
        .navigationTitle("Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(
                    destination: {
                        let newProfile = Profile(accountId: selectedProfile.accountId)
                        ProfileSection(
                            profile: newProfile,
                            fresh: true,
                            onDismiss: {
                                onDismiss()
                                await self.selectProfile(profile: newProfile)
                            }
                        )
                    },
                    label: {
                        Text("Create")
                    }
                )
            }
        })
        .task {
            if case .empty = profiles {
                do {
                    self.profiles = .success(try await accountController.queryProfiles())
                }catch let error {
                    self.profiles = .error(error)
                }
            }
        }
    }
    
    @ViewBuilder
    private func loadedBody(profiles: [Profile]) -> some View {
        let groupedProfiles = Dictionary(grouping: profiles, by: { $0.category ?? "Unknown" })
            .sorted { $0.key < $1.key }
        ForEach(groupedProfiles, id: \.key) { category, profiles in
            Section(header: Text(category)) {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(profiles) { profile in
                        profileCard(profile: profile)
                        if(profile != profiles.last) {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func profileCard(profile: Profile) -> some View {
        Button(
            action: {
                if(selectedProfile != profile) {
                    self.onDismiss()
                    Task {
                        await self.selectProfile(profile: profile)
                    }
                }
            },
            label: {
                HStack {
                    ProfileView(accountName: profile.displayName)
                        .frame(width: 48, height: 48)
                        .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                        .layoutPriority(1)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(profile.displayName)
                            .font(.title2)
                        Text(selectedProfile == profile ? "Selected profile" : "Select profile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .layoutPriority(1)
                    
                    Spacer()
                    
                    if(selectedProfile == profile) {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .layoutPriority(1)
                    }
                }
            }
        )
        .accentColor(colorScheme == .dark ? .white : .black)
    }
    
    private func selectProfile(profile: Profile) async {
        await accountController.activateProfile(profileId: profile.profileId)
        await accountController.loadDashboard()
        await scheduleController.loadData()
        await libraryController.loadWatchlists()
        await libraryController.loadWatchHistory(reset: true)
    }
}
