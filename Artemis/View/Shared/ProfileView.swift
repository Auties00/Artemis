//
//  ProfileView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 18/07/24.
//

import SwiftUI

struct ProfileView: View {
    private let initials: String
    init(accountName: String) {
        self.initials = accountName.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .reduce("") { partialResult, word in partialResult + String(word.first!.uppercased()) }
    }
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                Color.gray
                Text(initials)
                    .font(.system(size: g.size.width * 0.8))
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .modifier(FitInitials())
                    .padding(2)
            }
        }
    }
}

private struct FitInitials: ViewModifier {
    private let fraction: CGFloat = 1
    
    func body(content: Content) -> some View {
        GeometryReader { g in
            VStack {
                Spacer()
                content
                    .font(.system(size: 1000))
                    .minimumScaleFactor(0.005)
                    .lineLimit(1)
                    .frame(width: g.size.width * self.fraction)
                Spacer()
            }
        }
    }
}
