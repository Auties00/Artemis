//
//  BillingDetailsRequest.swift
//  Hidive
//
//  Created by Alessandro Autiero on 09/08/24.
//

import Foundation

struct BillingDetailsRequest: Encodable {
    let address: Address
    let fullName: String
    let email: String
}
