//
//  Account.swift
//  Hidive
//
//  Created by Alessandro Autiero on 12/07/24.
//

import Foundation

struct Account {
    let email: String?
    let name: String?
    init(email: String? = nil, name: String? = nil) {
        self.email = email
        self.name = name
    }
}
