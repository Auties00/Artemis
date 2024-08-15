//
//  LoginError.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import Foundation

enum LoginError : LocalizedError {
    case invalidCredentials
    case missingData(name: String)
    
    var errorDescription: String? {
        get {
            switch self {
            case .invalidCredentials:
                return "Invalid credentials"
            case .missingData:
                return "Server error"
            }
        }
    }
    
    var recoverySuggestion: String? {
        get {
            switch self {
            case .invalidCredentials:
                return "Check your email and/or password and try again"
            case .missingData:
                return "Please retry later"
            }
        }
    }
}
