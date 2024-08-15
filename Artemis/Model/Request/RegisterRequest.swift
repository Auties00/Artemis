//
//  RegisterRequest.swift
//  Hidive
//
//  Created by Alessandro Autiero on 03/08/24.
//

import Foundation

struct RegisterRequest: Encodable {
    let email: String
    let secret: String
    let consentAnswers: [ConsentAnswer]
}

struct ConsentAnswer: Encodable {
    let answer: Bool
    let promptField: String
}
