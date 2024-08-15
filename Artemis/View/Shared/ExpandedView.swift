//
//  ExpandedView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import SwiftUI

struct ExpandedView<Content>: View where Content : View {
    private let geometry: GeometryProxy
    private let widthExtension: CGFloat
    private let heightExtension: CGFloat
    private let content: () -> Content
    init(geometry: GeometryProxy, widthExtension: CGFloat = 0, heightExtension: CGFloat = 0, @ViewBuilder content: @escaping () -> Content) {
        self.geometry = geometry
        self.widthExtension = widthExtension
        self.heightExtension = heightExtension
        self.content = content
    }
    
    var body: some View {
        content()
            .frame(width: geometry.size.width + widthExtension)
            .frame(minHeight: geometry.size.height + heightExtension)
            .listRowBackground(Color.clear)
            .id(UUID())
    }
}
