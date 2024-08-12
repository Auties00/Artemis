//
//  SeriesDescriptionSheet.swift
//  Hidive
//
//  Created by Alessandro Autiero on 23/07/24.
//

import SwiftUI

struct WrappingSheet<Content>: View where Content: View {
    private let title: String
    private let onDismiss: () -> Void
    private let content: () -> Content
    @State
    private var size: CGFloat = .zero
    init(title: String, onDismiss: @escaping () -> Void, content: @escaping () -> Content) {
        self.title = title
        self.onDismiss = onDismiss
        self.content = content
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                content()
                    .fixedInnerHeight($size)
            }
            .navigationBarTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ExitButtonView() {
                        onDismiss()
                    }
                }
            })
        }
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

extension View {
    func fixedInnerHeight(_ sheetHeight: Binding<CGFloat>) -> some View {
        padding()
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(key: InnerHeightPreferenceKey.self, value: proxy.size.height)
                }
            }
            .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in sheetHeight.wrappedValue = newHeight }
            .presentationDetents([.height(sheetHeight.wrappedValue)])
    }
}
