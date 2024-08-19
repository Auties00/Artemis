//
//  ErrorCancellation.swift
//   Artemis
//
//  Created by Alessandro Autiero on 06/08/24.
//

import Foundation

extension Error {
    var isCancelledRequestError: Bool {
        if let error = self as? URLError, error.code == URLError.Code.cancelled {
            return true
        }else {
            return false
        }
    }
    
    var isNoConnectionError: Bool {
        if let error = self as? URLError, error.code == URLError.Code.notConnectedToInternet {
            return true
        }else {
            return false
        }
    }
}
