//
//  ConnectivityController.swift
//   Artemis
//
//  Created by Alessandro Autiero on 06/08/24.
//

import Foundation
import Network

@Observable
class ConnectivityController {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "ConnectivityController.Queue")
    var isConnected = false

    init() {
        networkMonitor.pathUpdateHandler = { path in
            let newValue = path.status == .satisfied
            if(self.isConnected != newValue) {
                self.isConnected = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: workerQueue)
    }
}
