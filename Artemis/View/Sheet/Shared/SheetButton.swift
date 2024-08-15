//
//  SheetButton.swift
//  Hidive
//
//  Created by Alessandro Autiero on 02/08/24.
//

import Foundation
import SwiftUI

struct SheetButton: View {
    @Environment(\.colorScheme)
    private var colorScheme
    
    private let image: String
    private let onTap: () -> Void
    init(image: String, onTap: @escaping () -> Void) {
        self.image = image
        self.onTap = onTap
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: colorScheme == .dark ? 0.19 : 0.93))
                .frame(width: 30, height: 30)
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .font(Font.body.weight(.bold))
                .scaleEffect(0.416)
                .foregroundColor(Color(white: colorScheme == .dark ? 0.62 : 0.51))
        }
        .onTapGesture {
            onTap()
        }
    }
}
