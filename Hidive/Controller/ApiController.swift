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
    "realm": "dce.hidive",
    "X-Device-Id": "iPhone16,2"
]

@Observable
final class ApiController {
    private let executor: ApiTaskExecutor = ApiTaskExecutor()
    private let encoder: JSONEncoder = JSONEncoder()
    private let decoder: JSONDecoder = JSONDecoder()
    
    var authorisationToken: String? {
        get {
            access(keyPath: \.authorisationToken)
            return UserDefaults.standard.string(forKey: "authorisationToken")
        }
        set {
            withMutation(keyPath: \.authorisationToken) {
                UserDefaults.standard.setValue(newValue, forKey: "authorisationToken")
            }
        }
    }
    
    var refreshToken: String? {
        get {
            access(keyPath: \.refreshToken)
            return UserDefaults.standard.string(forKey: "refreshToken")
        }
        set {
            withMutation(keyPath: \.refreshToken) {
                UserDefaults.standard.setValue(newValue, forKey: "refreshToken")
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
    
    func onLoggedIn() async {
        await executor.markReady()
    }
    
    func hasTokens() -> Bool {
        return authorisationToken != nil && refreshToken != nil;
    }
    
    func sendRequest<T : Decodable>(method: String, url: String? = nil, path: String = "", data: Encodable? = nil, additionalHeaders: [String:String]? = nil, log: Bool = false, requiresLogin: Bool = true) async throws -> T {
        let response: Data = try await sendRequest(method: method, url: url, path: path, data: data, additionalHeaders: additionalHeaders, log: log, requiresLogin: requiresLogin)
        do {
            return try decoder.decode(T.self, from: response)
        } catch DecodingError.dataCorrupted {
            throw RequestError.decodeError("Corrupted data")
        } catch let DecodingError.keyNotFound(key, context) {
            throw RequestError.decodeError("Key '\(key.stringValue)' not found at \(context.codingPath)")
        } catch let DecodingError.valueNotFound(value, context) {
            throw RequestError.decodeError("Value '\(value)' not found at \(context.codingPath)")
        } catch let DecodingError.typeMismatch(type, context)  {
            throw RequestError.decodeError("Type mismatch for '\(type)' at \(context.codingPath)")
        } catch {
            throw RequestError.decodeError("Unknown error")
        }
    }
    
    func sendRequest(method: String, url: String? = nil, path: String = "", data: Encodable? = nil, additionalHeaders: [String:String]? = nil, log: Bool = false, requiresLogin: Bool = true) async throws -> String {
        let response: Data = try await sendRequest(method: method, url: url, path: path, data: data, additionalHeaders: additionalHeaders, log: log, requiresLogin: requiresLogin)
        return String(data: response, encoding: .utf8)!
    }
    
    private func sendRequest(method: String, url: String?, path: String, data: Encodable?, additionalHeaders: [String:String]?, log: Bool, requiresLogin: Bool, isRetry: Bool = false) async throws -> Data {
        if(requiresLogin) {
            await executor.wait()
        }
        
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
        if(method == "POST" || method == "PUT") {
            requestHeaders["Content-Type"] = "application/json"
        }
        if let additionalHeaders = additionalHeaders {
            requestHeaders = requestHeaders.merging(additionalHeaders, uniquingKeysWith: {(first, second) in second })
        }
        request.allHTTPHeaderFields = requestHeaders
        
        let (responseBody, response) = try await URLSession.shared.data(for: request)
        
        if(log) {
            print("Response: \(String(data: responseBody, encoding: .utf8) ?? "<nothing>")")
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            if(httpResponse.statusCode == 401) {
                if(isRetry) {
                    throw RequestError.failedRefresh
                }
                
                try await refreshToken()
                return try await self.sendRequest(
                    method: method,
                    url: url,
                    path: path,
                    data: data,
                    additionalHeaders: additionalHeaders,
                    log: log,
                    requiresLogin: requiresLogin,
                    isRetry: true
                )
            }else if(!String(httpResponse.statusCode).starts(with: "20")) {
                throw RequestError.invalidResponseStatusCode(httpResponse.statusCode)
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

private actor ApiTaskExecutor {
    private var ready: Bool
    private var waiters: [CheckedContinuation<Void, Never>]
    init() {
        self.ready = false
        self.waiters = []
    }

    func wait() async {
        if(ready) {
            return
        }
        
        await withCheckedContinuation {
            waiters.append($0)
        }
    }

    func markReady() {
        if(ready) {
            return
        }
    
        self.ready = true
        for waiter in waiters {
            waiter.resume()
        }
        waiters.removeAll()
    }
}
