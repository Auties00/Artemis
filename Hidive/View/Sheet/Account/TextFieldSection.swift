//
//  TextFieldSection.swift
//  Hidive
//
//  Created by Alessandro Autiero on 09/08/24.
//

import SwiftUI

struct TextFieldSection: View {
    @FocusState
    private var focused: Bool
    private let hint: String
    private let title: String
    private let value: Binding<String>
    init(hint: String, title: String, value: Binding<String>) {
        self.hint = hint
        self.title = title
        self.value = value
    }
    
    var body: some View {
        NavigationLink {
            List {
                Section(header: Text(hint)) {
                    TextField("", text: value)
                        .focused($focused)
                        .onAppear {
                            self.focused = true
                        }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            Text(title)
            Spacer()
                .frame(maxWidth: .infinity)
            Text(value.wrappedValue)
                .foregroundColor(.secondary)
                .layoutPriority(1)
        }
    }
}
