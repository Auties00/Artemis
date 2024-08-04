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
        ZStack {
            Circle()
                .fill(Color(white: colorScheme == .dark ? 0.19 : 0.93))
                .frame(width: 30, height: 30)
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .font(Font.body.weight(.bold))
                .scaleEffect(0.416)
                .foregroundColor(Color(white: colorScheme == .dark ? 0.62 : 0.51))
        }.onTapGesture {
            onTap()
        }
    }
}
