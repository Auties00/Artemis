//
//  ExpandedView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import SwiftUI

struct ExpandedView<Content>: View where Content : View {
    private let geometry: GeometryProxy
    private let content: () -> Content
    init(geometry: GeometryProxy, content: @escaping () -> Content) {
        self.geometry = geometry
        self.content = content
    }
    
    var body: some View {
        content()
            .frame(width: geometry.size.width)
            .frame(minHeight: geometry.size.height)
    }
}
