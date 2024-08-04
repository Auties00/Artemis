//
//  ErrorView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import SwiftUI

struct ErrorView: View {
    private let error: Error
    init(error: Error) {
        self.error = error
    }
    
    var body: some View {
        let localizedError = LocalizedErrorWrapper(error: error)
        InformationView(
            title: localizedError.localizedDescription,
            description: localizedError.recoverySuggestion ?? ""
        )
    }
}
