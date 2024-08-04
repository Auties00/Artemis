//
//  RequestError.swift
//  Hidive
//
//  Created by Alessandro Autiero on 09/07/24.
//

import Foundation

enum RequestError : LocalizedError {
    case invalidUrl
    case invalidConnection
    case invalidRequestData(Error? = nil)
    case invalidResponseData(Error? = nil)
    case failedRefresh
    
    var errorDescription: String? {
        get {
            switch self {
            case .invalidUrl:
                return "Invalid url"
            case .invalidConnection:
                return "Cannot connect to the server"
            case .invalidRequestData:
                return "Invalid request data"
            case .invalidResponseData:
                return "Invalid response data"
            case .failedRefresh:
                return "Invalid session"
            }
        }
    }
    
    var recoverySuggestion: String? {
        get {
            switch self {
            case .invalidUrl:
                return "Please report this issue"
            case .invalidRequestData(error: let error):
                return error?.localizedDescription ?? "Unknown cause"
            case .invalidResponseData(error: let error):
                return error?.localizedDescription ?? "Unknown cause"
            case .invalidConnection:
                return "Please try again later"
            case .failedRefresh:
                return "Cannot refresh auth token"
            }
        }
    }
}
