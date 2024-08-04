//
//  InformationView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import SwiftUI

struct InformationView: View {
    private let title: String
    private let description: String?
    init(title: String, description: String) {
        self.title = title
        self.description = description
    }
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .lineSpacing(8)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHeading(.h1)
                .padding(.horizontal, 15 + iPhoneDimensions.horizontalPaddingAddend)
            
            if(description != nil) {
                Text(description!)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 15 + iPhoneDimensions.horizontalPaddingAddend)
            }
        }.listRowBackground(Color.clear)
    }
}

