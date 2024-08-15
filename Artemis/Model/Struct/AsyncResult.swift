//
//  AsyncResult.swift
//  Hidive
//
//  Created by Alessandro Autiero on 12/07/24.
//

import Foundation
import SwiftUI

enum AsyncResult<Success> {
    case empty
    case loading
    case success(Success)
    case error(Error)
    
    var isWaiting: Bool {
        switch(self) {
        case .empty, .loading:
            return true
        default:
            return false
        }
    }
    
    var value: Success? {
        get {
            if case .success(let value) = self {
                return value
            }else {
                return nil
            }
        }
        
        set { // Fake binding
            
        }
    }
    
    var error: Error? {
        if case .error(let error) = self {
            return error
        }else {
            return nil
        }
    }
}
