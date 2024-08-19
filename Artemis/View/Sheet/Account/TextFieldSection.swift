//
//  TextFieldSection.swift
//   Artemis
//
//  Created by Alessandro Autiero on 09/08/24.
//

import SwiftUI

struct TextFieldSection: View {
    private let hint: String
    private let title: String
    private let value: Binding<String>
    private let onUpdate: () -> Void
    init(hint: String, title: String, value: Binding<String>, onUpdate: @escaping () -> Void) {
        self.hint = hint
        self.title = title
        self.value = value
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        NavigationLink {
            TextFieldPage(hint: hint, title: title, value: value, onUpdate: onUpdate)
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

private struct TextFieldPage: View {
    @Environment(\.dismiss)
    private var dismiss
    
    @FocusState
    private var focused: Bool
    
    @State
    private var originalValue: String
    
    @State
    private var dismissed: Bool = false
    
    private let hint: String
    private let title: String
    private let value: Binding<String>
    private let onUpdate: () -> Void
    init(hint: String, title: String, value: Binding<String>, onUpdate: @escaping () -> Void) {
        self.hint = hint
        self.title = title
        self._originalValue = State(initialValue: value.wrappedValue)
        self.value = value
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        List {
            Section(header: Text(hint)) {
                TextField("", text: value)
                    .focused($focused, equals: true)
                    .onAppear {
                        self.focused = true
                    }
                    .onSubmit(goBack)
                    .showClearButton(value)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func goBack() {
        if(dismissed) {
            return
        }
        
        self.dismissed = true
        onUpdate()
        dismiss()
    }
}

private extension View {
    func showClearButton(_ text: Binding<String>) -> some View {
        self.modifier(TextFieldClearButton(fieldText: text))
    }
}

private struct TextFieldClearButton: ViewModifier {
    @Binding var fieldText: String

    func body(content: Content) -> some View {
        content
            .overlay {
                if !fieldText.isEmpty {
                    HStack {
                        Spacer()
                        Button {
                            fieldText = ""
                        } label: {
                            Image(systemName: "multiply.circle.fill")
                        }
                        .foregroundColor(.secondary)
                        .padding(.trailing, 4)
                    }
                }
            }
    }
}
