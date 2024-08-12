//
//  ProfileSection.swift
//  Hidive
//
//  Created by Alessandro Autiero on 03/08/24.
//

import SwiftUI
import AlertToast

struct ProfileSection: View {
    @State
    private var profileName: String
    
    @FocusState
    private var profileNameFocused: Bool
    
    @State
    private var audioLanguage: String
    
    @State
    private var subtitlesLanguage: String
    
    @State
    private var timeskips: Bool = true
    
    @State
    private var autoPlay: Bool
    
    @State
    private var creating: Bool = false
    
    @State
    private var deleting: Bool = false
    
    @State
    private var error: Bool = false
    
    @State
    private var errorMessage: String? = nil
    
    @State
    private var profileUpdateTask: Task<Void, Error>?
    
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme
    
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    @Environment(ScheduleController.self)
    private var scheduleController: ScheduleController
    
    @Environment(LibraryController.self)
    private var libraryController: LibraryController
    
    @Environment(AnimeController.self)
    private var animeController: AnimeController
    
    private let profile: Profile
    private let fresh: Bool
    private let onDismiss: () async -> Void
    init(profile: Profile, fresh: Bool, onDismiss: @escaping () async -> Void) {
        self.profile = profile
        self.fresh = fresh
        self.onDismiss = onDismiss
        self._profileName = State(initialValue: profile.displayName)
        self._audioLanguage = State(initialValue: profile.preferences.audioLanguage)
        let subtitlesLanguage = profile.preferences.subtitlesLanguage
        self._subtitlesLanguage = State(initialValue: subtitlesLanguage)
        self._autoPlay = State(initialValue: profile.preferences.autoAdvance)
    }
    
    var body: some View {
        let result = loadedBody()
        if(fresh) {
            result
                .navigationTitle("New Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toast(isPresenting: $creating) {
                    AlertToast(type: .loading, title: "Creating profile...")
                }
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(
                            action: {
                                saveProfile()
                            },
                            label: {
                                Text("Confirm")
                            }
                        )
                    }
                })
        }else {
            result
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toast(isPresenting: $deleting) {
                    AlertToast(type: .loading, title: "Deleting profile...")
                }
                .onChange(of: profileName) { _, profileName in
                    profile.displayName = profileName
                    updateProfile()
                }
                .onChange(of: audioLanguage) { _, audioLanguage in
                    profile.preferences.audioLanguage = audioLanguage
                    updateProfile()
                }
                .onChange(of: subtitlesLanguage) { _, subtitlesLanguage in
                    profile.preferences.subtitlesLanguage = subtitlesLanguage
                    updateProfile()
                }
                .onChange(of: autoPlay) { _, autoPlay in
                    profile.preferences.autoAdvance = autoPlay
                    updateProfile()
                }
        }
    }
    
    @ViewBuilder
    private func loadedBody() -> some View {
        List {
            Section(header: Text("Information")) {
                TextFieldSection(
                    hint: "Type a name",
                    title: "Name",
                    value: $profileName
                )
            }
            
            Section(header: Text("Language")) {
                languageSelector(
                    title: "Audio",
                    options: ProfilePreferences.supportedAudioLanguages,
                    selection: $audioLanguage
                )
                languageSelector(
                    title: "Subtitles",
                    options: ProfilePreferences.supportedSubtitlesLanguages,
                    selection: $subtitlesLanguage
                )
            }
            
            Section(header: Text("Preferences")) {
                Toggle("Autoplay", isOn: $autoPlay)
                Toggle("Timeskips (Beta)", isOn: $timeskips)
            }
            
            if(profile.category?.caseInsensitiveCompare("main") != .orderedSame) {
                Section(header: Text("Management")) {
                    Button(
                        action: {
                            deleteProfile()
                        },
                        label: {
                            Text("Delete profile")
                                .foregroundColor(.red)
                        }
                    )
                }
            }
        }
        .toast(isPresenting: $error) {
            return AlertToast(type: .error(Color.red), title: "Profile Error", subTitle: errorMessage ?? "Unknown")
        }
    }
    
    @ViewBuilder
    private func languageSelector(title: String, options: [String], selection: Binding<String>) -> some View {
        NavigationLink {
            List {
                Section(header: Text("Select a language")) {
                    let selectedOption = getSelectedLanguage(selection: selection.wrappedValue, options: options)
                    ForEach(options, id: \.self) { key in
                        Button(
                            action: {
                                selection.wrappedValue = key
                            },
                            label: {
                                HStack {
                                    Text(Locale.current.localizedString(forIdentifier: key) ?? "Off")
                                        .layoutPriority(1)
                                    if(selectedOption == key) {
                                        Spacer()
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
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            Text(title)
            Spacer()
                .frame(maxWidth: .infinity)
            Text(Locale.current.localizedString(forIdentifier: selection.wrappedValue) ?? "Off")
                .foregroundColor(.secondary)
                .layoutPriority(1)
        }
    }
    
    private func getSelectedLanguage(selection: String, options: [String]) -> String? {
        if let equal = options.first(where: { $0 == selection }){
            return equal
        }
        
        let simpleLocale = selection.split(separator: "-", maxSplits: 2)[0]
        return options.first(where: { $0.split(separator: "-", maxSplits: 2)[0] == simpleLocale })
    }
    
    private func updateProfile() {
        self.profileUpdateTask?.cancel()
        self.profileUpdateTask = Task {
            try await Task.sleep(for: .seconds(1))
            try await accountController.updateProfile(profile: profile)
        }
    }
    
    private func saveProfile() {
        if(creating) {
            return
        }
        
        self.creating = true
        Task {
            do {
                try await accountController.saveProfile(profile: profile)
                self.creating = false
                await self.onDismiss()
            }catch let error as RequestError {
                self.creating = false
                self.error = true
                self.errorMessage = if case .invalidResponseStatusCode(let statusCode) = error {
                    statusCode == 422 ? "Too many profiles" : error.localizedDescription
                }else {
                    error.localizedDescription
                }
            }catch let error {
                self.creating = false
                self.error = true
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func deleteProfile() {
        if(deleting) {
            return
        }
        
        self.deleting = true
        Task {
            do {
                try await accountController.deleteProfile(profile: profile)
                await accountController.activateProfile()
                await onDismiss()
                self.deleting = false
                await animeController.clearCache()
                await accountController.loadDashboard()
                await scheduleController.loadData()
                await libraryController.loadWatchlists()
                await libraryController.loadWatchHistory(reset: true)
            }catch let error {
                self.deleting = false
                self.error = true
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
