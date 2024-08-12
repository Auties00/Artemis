//
//  ResetPasswordRequest.swift
//  Hidive
//
//  Created by Alessandro Autiero on 03/08/24.
//

import Foundation

struct ResetPasswordRequest: Encodable {
    let id: String
    let provider: String
}
