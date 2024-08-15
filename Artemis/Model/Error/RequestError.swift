//
//  RequestError.swift
//  Hidive
//
//  Created by Alessandro Autiero on 09/07/24.
//

import Foundation

enum RequestError : LocalizedError {
    case invalidUrl
    case decodeError(String)
    case invalidRequestData(Error? = nil)
    case invalidResponseStatusCode(Int, String? = nil)
    case invalidResponseData(Error? = nil)
    case failedRefresh
    
    var errorDescription: String? {
        get {
            switch self {
            case .invalidUrl:
                return "Invalid url"
            case .decodeError:
                return "Cannot decode response"
            case .invalidRequestData:
                return "Invalid request data"
            case .invalidResponseStatusCode(let statusCode, _):
                return "Status code \(statusCode)"
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
            case .decodeError(let error):
                return error
            case .invalidRequestData(let error):
                return error?.localizedDescription ?? "Unknown cause"
            case .invalidResponseData(let error):
                return error?.localizedDescription ?? "Unknown cause"
            case .invalidResponseStatusCode(_, let message):
                return message ?? "Please try again later"
            case .failedRefresh:
                return "Cannot refresh auth token"
            }
        }
    }
}
