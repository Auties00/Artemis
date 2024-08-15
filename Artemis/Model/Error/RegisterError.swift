//
//  RegisterError.swift
//  Hidive
//
//  Created by Alessandro Autiero on 03/08/24.
//

import Foundation

enum RegisterError : LocalizedError {
    case invalidCode(code: String)
    
    var errorDescription: String? {
        get {
            switch self {
            case .invalidCode(let code):
                switch(code) {
                case "GEO_RESTRICTION":
                    return "HIDIVE is not supported in your country"
                case "CONFLICT":
                    return "An account with this email already exists"
                case "CONFIRM_PASSWORD":
                    return "The passwords you provided don't match"
                case "422":
                    return "Make sure you are using a valid email and a password that is at least four characters long"
                default:
                    return "Unknown error"
                }
            }
        }
    }
}
