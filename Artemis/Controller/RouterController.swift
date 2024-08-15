//
//  RouterController.swift
//  Hidive
//
//  Created by Alessandro Autiero on 04/08/24.
//

import Foundation
import SwiftUI

@Observable
class RouterController {
    var path: NavigationPath = NavigationPath()
    
    private var doubleTapHandler: (() -> Bool)?
    var pathHandler: () -> Bool {
        get {
            return doubleTapHandler ?? { false }
        }
        set(pathHandler) {
            self.doubleTapHandler = pathHandler
        }
    }
    
    var addToWatchlistItem: DescriptableEntry?
}
