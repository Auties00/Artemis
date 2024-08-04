//
//  AccountController.swift
//  Hidive
//
//  Created by Alessandro Autiero on 09/07/24.
//

import Foundation
import SwiftUI

private let endpoint: String = "https://dce-frontoffice.imggaming.com/api"
private let headers: [String: String] = [
    "X-Api-Key": "f086d846-37ed-4761-99ac-e538c03e5701",
    "X-App-Var": "2.5.1",
    "User-Agent": "HIDIVE/126 CFNetwork/1496.0.7 Darwin/23.5.0",
    "realm": "dce.hidive"
]

@Observable
final class ApiController: ObservableObject {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    init() {
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }
    
    var authorisationToken: String? {
        get {
            access(keyPath: \.authorisationToken)
            return UserDefaults.standard.string(forKey: "authorisationToken123")
        }
        set {
            withMutation(keyPath: \.authorisationToken) {
                UserDefaults.standard.setValue(newValue, forKey: "authorisationToken123")
            }
        }
    }
    
    var refreshToken: String? {
        get {
            access(keyPath: \.refreshToken)
            return UserDefaults.standard.string(forKey: "refreshToken123")
        }
        set {
            withMutation(keyPath: \.refreshToken) {
                UserDefaults.standard.setValue(newValue, forKey: "refreshToken123")
            }
        }
    }
    
    var loggedIn: Bool {
        get {
            access(keyPath: \.loggedIn)
            return UserDefaults.standard.bool(forKey: "loggedIn")
        }
        set {
            withMutation(keyPath: \.loggedIn) {
                UserDefaults.standard.setValue(newValue, forKey: "loggedIn")
            }
        }
    }
    
    func hasTokens() -> Bool {
        return authorisationToken != nil && refreshToken != nil;
    }
    
    func sendRequest<T : Decodable>(method: String, url: String? = nil, path: String = "", data: Encodable? = nil, log: Bool = false) async throws -> T {
        do {
            let response: Data = try await sendRequest(method: method, url: url, path: path, data: data, log: log)
            return try decoder.decode(T.self, from: response)
        }catch let error {
            throw RequestError.invalidResponseData(error)
        }
    }
    
    func sendRequest(method: String, url: String? = nil, path: String = "", data: Encodable? = nil, log: Bool = false) async throws -> String {
        do {
            let response: Data = try await sendRequest(method: method, url: url, path: path, data: data, log: log)
            return String(data: response, encoding: .utf8)!
        }catch let error {
            throw RequestError.invalidResponseData(error)
        }
    }
    
    private func sendRequest(method: String, url: String? = nil, path: String = "", data: Encodable? = nil, log: Bool = false, isRetry: Bool = false) async throws -> Data {
        let requestUrlSource = url ?? "\(endpoint)/\(path)"
        if(log) {
            print("Request: \(requestUrlSource)")
        }
        
        guard let requestUrl = URL(string: requestUrlSource) else {
            throw RequestError.invalidUrl
        }
        
        var request = URLRequest(url: requestUrl)
        
        request.httpMethod = method
        
        if(data != nil) {
            do {
                let payload = try encoder.encode(data!)
                request.httpBody = payload
            }catch let serializationError {
                throw RequestError.invalidRequestData(serializationError)
            }
        }
        
        var requestHeaders: [String: String] = self.prepareHeaders()
        if(method == "POST") {
            requestHeaders["Content-Type"] = "application/json"
        }
        request.allHTTPHeaderFields = requestHeaders
        
        guard let (responseBody, response) = try? await URLSession.shared.data(for: request) else {
            throw RequestError.invalidConnection
        }
        
        if(log) {
            print(String(data: responseBody, encoding: .utf8))
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            if(httpResponse.statusCode == 401) {
                if(isRetry) {
                    throw RequestError.invalidResponseData()
                }
                
                try await refreshToken()
                return try await self.sendRequest(
                    method: method,
                    path: path,
                    data: data,
                    isRetry: true
                )
            }
        }
        
        return responseBody
    }
    
    private func refreshToken() async throws {
        if(refreshToken == nil) {
            throw RequestError.invalidResponseData()
        }
        
        let request = RefreshTokenRequest(refreshToken: refreshToken!)
        let response: RefreshTokenResponse = try await sendRequest(
            method: "POST",
            path: "v2/token/refresh",
            data: request
        )
        if(response.authorisationToken == nil) {
            throw RequestError.invalidResponseData()
        }
        
        self.authorisationToken = response.authorisationToken
    }
    
    func prepareHeaders() -> [String:String] {
        var requestHeaders: [String: String] = headers
        let authorisationToken = self.authorisationToken
        if(authorisationToken != nil) {
            requestHeaders["Authorization"] = "Bearer \(authorisationToken!)"
        }
        return requestHeaders
    }
}
