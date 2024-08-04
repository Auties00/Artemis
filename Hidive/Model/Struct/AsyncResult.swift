//
//  AsyncResult.swift
//  Hidive
//
//  Created by Alessandro Autiero on 12/07/24.
//

import Foundation

enum AsyncResult<Success> {
    case empty
    case loading
    case success(Success)
    case failure(Error)
}
