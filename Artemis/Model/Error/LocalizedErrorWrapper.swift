//
//  LocalizedErrorWrapper.swift
//   Artemis
//
//  Created by Alessandro Autiero on 12/07/24.
//

import Foundation

struct LocalizedErrorWrapper: LocalizedError {
    private let underlyingError: Error?
    init(error: Error?) {
        self.underlyingError = error
    }
    
    var errorDescription: String? {
        (underlyingError as? LocalizedError)?.errorDescription ?? underlyingError?.localizedDescription
    }
    
    var recoverySuggestion: String? {
        (underlyingError as? LocalizedError)?.recoverySuggestion
    }
}
