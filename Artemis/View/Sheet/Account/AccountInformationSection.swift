//
//  NotificationsSection.swift
//   Artemis
//
//  Created by Alessandro Autiero on 04/08/24.
//

import SwiftUI

struct AccountInformationSection: View {
    @State
    private var details: AsyncResult<Details> = .empty
    
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
                Text(detailsBinding.email)
            } label: {
                Text("Email")
            }
            
            LabeledContent {
                Text(detailsBinding.fullName)
            } label: {
                Text("Full name")
            }
        }
        
        Section(header: Text(details.address.label)) {
            LabeledContent {
                if let entry = details.address.countryCode {
                    Text(details.metadata.countries[entry]?.name ?? "")
                }
            } label: {
                Text("Country")
            }
            
            let selectedCountryCode = details.address.countryCode ?? ""
            let selectedCountry = details.metadata.countries[selectedCountryCode]
            if let selectedStateField = selectedCountry?.addressRequiredFields["administrativeLevel1"] {
                LabeledContent {
                    if let entry = details.address.administrativeLevel1 {
                        Text(selectedStateField.acceptableValues[entry] ?? "")
                    }
                } label: {
                    Text("State")
                }
            }
            
            LabeledContent {
                Text(detailsBinding.address.postalCode)
            } label: {
                Text("ZIP Code")
            }
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
