//
//  RouterController.swift
//   Artemis
//
//  Created by Alessandro Autiero on 04/08/24.
//

import Foundation
import SwiftUI

@Observable
class RouterController {
    var path: [NestedPageType] = []
    
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
