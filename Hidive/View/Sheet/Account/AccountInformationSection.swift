//
//  NotificationsSection.swift
//  Hidive
//
//  Created by Alessandro Autiero on 04/08/24.
//

import SwiftUI

struct AccountInformationSection: View {
    @State
    private var details: AsyncResult<Details> = .empty
    @State
    private var billingDetailsTask: Task<Void, Error>?
    @Environment(AccountController.self)
    private var accountController: AccountController
    
    var body: some View {
        GeometryReader { geometry in
            List {
                switch(details) {
                case .empty, .loading:
                    ExpandedView(geometry: geometry) {
                        LoadingView()
                    }
                case .success(let details):
                    loadedBody(details: details)
                case .error(let error):
                    ExpandedView(geometry: geometry) {
                        ErrorView(error: error)
                    }
                }
            }
        }
        .navigationTitle("Information")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if case .empty = details {
                do {
                    self.details = .loading
                    let metadata = try await accountController.getCountries()
                    let address = try await accountController.getAddress()
                    let details = try await accountController.getDetails()
                    let email = details.id
                    let fullName = details.name?.fullName ?? ""
                    self.details = .success(Details(email: email, fullName: fullName, address: address, metadata: metadata))
                }catch let error {
                    self.details = .error(error)
                }
            }
        }
    }
    
    @ViewBuilder
    private func loadedBody(details: Details) -> some View {
        @Bindable
        var detailsBinding = details
        
        Section(header: Text("Contact Information")) {
            LabeledContent {
                TextField("Email", text: $detailsBinding.email)
                    .disabled(true)
                    .colorMultiply(.gray)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text("Email")
            }
            
            TextFieldSection(
                hint: "Type a full name",
                title: "Full name",
                value: $detailsBinding.fullName
            )
        }
        
        Section(header: Text(details.address.label)) {
            optionSelector(
                title: "Country",
                options: Array(details.metadata.countries.keys),
                selection: $detailsBinding.address.countryCode,
                displayName: { entry in
                    if let entry = entry {
                        return details.metadata.countries[entry]?.name
                    }else {
                        return nil
                    }
                }
            )
            
            let selectedCountryCode = details.address.countryCode ?? ""
            let selectedCountry = details.metadata.countries[selectedCountryCode]
            if let selectedStateField = selectedCountry?.addressRequiredFields["administrativeLevel1"] {
                optionSelector(
                    title: "State",
                    options: Array(selectedStateField.acceptableValues.keys),
                    selection: $detailsBinding.address.administrativeLevel1,
                    displayName: { entry in
                        if let entry = entry {
                            return selectedStateField.acceptableValues[entry]
                        }else {
                            return nil
                        }
                    }
                )
            }
            
            TextFieldSection(
                hint: "Type a zip code",
                title: "ZIP Code",
                value: $detailsBinding.address.postalCode.orElse("")
            )
        }.onChange(of: detailsBinding.address) { _, newValue in
            updateBillingDetails(details: details, address: newValue)
        }
    }
    
    @ViewBuilder
    private func optionSelector<Child: Hashable>(title: String, options: [Child?], selection: Binding<Child?>, displayName: @escaping (Child?) -> String?)  -> some View {
        NavigationLink {
            List {
                Section(header: Text("Select a \(title)")) {
                    Picker(title, selection: selection) {
                        ForEach(options, id: \.self) { key in
                            Text(displayName(key) ?? "")
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            Text(title)
            Spacer()
                .frame(maxWidth: .infinity)
            Text(displayName(selection.wrappedValue) ?? "")
                .foregroundColor(.secondary)
                .layoutPriority(1)
        }
    }
    
    private func updateBillingDetails(details: Details, address: Address) {
        self.billingDetailsTask?.cancel()
        self.billingDetailsTask = Task {
            try await Task.sleep(for: .seconds(1))
            try await accountController.updateBillingDetails(email: details.email, fullName: details.fullName, address: address)
        }
    }
}

@Observable
private class Details {
    var email: String
    var fullName: String
    var address: Address
    var metadata: CountriesResponse
    init(email: String, fullName: String, address: Address, metadata: CountriesResponse) {
        self.email = email
        self.fullName = fullName
        self.address = address
        self.metadata = metadata
    }
}

extension Binding {
    func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Binding<NewValue> {
           Binding<NewValue>(get: { transform(wrappedValue) }, set: { _ in })
       }
    
    func orElse<NewValue>(_ fallback: NewValue) -> Binding<NewValue> where Value == NewValue? {
        return Binding<NewValue>(get: {
            return self.wrappedValue ?? fallback
        }) { value in
            self.wrappedValue = value
        }
    }
}
