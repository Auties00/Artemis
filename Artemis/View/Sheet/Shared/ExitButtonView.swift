//
//  ExitButtonView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 11/07/24.
//

import Foundation
import SwiftUI

struct ExitButtonView: View {
    @Environment(\.colorScheme) 
    private var colorScheme
    
    private let onTap: () -> Void
    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }
    
    var body: some View {
        SheetButton(image: "xmark") {
            onTap()
        }
    }
}
