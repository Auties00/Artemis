//
//  AccountController.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import Foundation
import SwiftUI

@Observable
class AccountController: ObservableObject {
    private let apiController: ApiController
    init(apiController: ApiController) {
        self.apiController = apiController
    }
    
    var account: AsyncResult<Account> = .empty
    var dashboard: AsyncResult<DashboardResponse> = .empty
    
    func login() async {
        self.account = .loading
        if(apiController.loggedIn) {
            await queryAccountData()
        }else {
           await loginGuest()
        }
        await loadDashboard()
    }
    
    private func loginGuest() async {
        do {
            let payload = LoginRequest(id: , secret: <#T##String#>)
            let loginResponse: LoginResponse = try await apiController.sendRequest(
                method: "POST",
                path: "v2/login",
                data: payload
            )
            try await handleLoginResponse(loginResponse: response, loggedIn: false)
            self.account = .success(Account())
        }catch let error {
            self.account = .failure(error)
        }
    }
    
    func loginUser(payload: LoginRequest) async {
        self.account = .loading
        do {
            let loginResponse: LoginResponse = try await apiController.sendRequest(
                method: "POST",
                path: "v2/login",
                data: payload
            )
            try await handleLoginResponse(loginResponse: loginResponse, loggedIn: true)
            await queryAccountData()
        }catch let error {
            self.account = .failure(error)
            return
        }
        
        await loadDashboard()
    }
    
    private func handleLoginResponse(loginResponse: LoginResponse, loggedIn: Bool) async throws {
        let errorCode = loginResponse.code
        guard errorCode == nil else {
            throw LoginError.invalidCredentials(code: errorCode!)
        }
        
        guard let authorisationToken = loginResponse.authorisationToken else {
            throw LoginError.missingData(name: "authorisationToken")
        }
        
        guard let refreshToken = loginResponse.refreshToken else {
            throw LoginError.missingData(name: "refreshToken")
        }
        
        apiController.authorisationToken = authorisationToken
        apiController.refreshToken = refreshToken
        apiController.loggedIn = loggedIn
    }
    
    private func queryAccountData() async {
        do {
            let profileResponse: ProfileResponse = try await apiController.sendRequest(
                method: "GET",
                path: "v2/user/profile"
            )
            self.account = .success(Account(
                email: profileResponse.id,
                name: profileResponse.name?.fullName ?? profileResponse.id
            ))
        }catch let error {
            self.account = .failure(error)
        }
    }
    
    func loadDashboard() async {
        if case .success = account {
            do {
                self.dashboard = .loading
                let result: DashboardResponse = try await apiController.sendRequest(
                    method: "GET",
                    path: "v4/content/home?bpp=10&rpp=12&displaySectionLinkBuckets=SHOW&displayEpgBuckets=HIDE&displayEmptyBucketShortcuts=SHOW&displayContentAvailableOnSignIn=SHOW&displayGeoblocked=SHOW&bspp=20",
                    log: true
                )
                self.dashboard = .success(result)
            }catch let error {
                self.dashboard = .failure(error)
            }
        }
    }
    
    func isLoggedIn() -> Bool {
        return apiController.loggedIn
    }
    
    func logout() async {
        apiController.authorisationToken = nil
        apiController.refreshToken = nil
        apiController.loggedIn = false
        await self.loginGuest()
    }
}
