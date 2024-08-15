//
//  BackButtonView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 23/07/24.
//

import SwiftUI

struct SeriesToolbarButtonView: View {
    private let iconName: String
    private let foregroundColor: Bool
    private let backgroundColor: SeriesToolbarButtonBackgroundType
    private let bold: Bool
    private let large: Bool
    private let label: String?
    private let labelOpacity: Double
    private let action: () -> Void
    init(iconName: String, foregroundColor: Bool, backgroundColor: SeriesToolbarButtonBackgroundType, bold: Bool, large: Bool, label: String? = nil, labelOpacity: Double = 1, action: @escaping () -> Void) {
        self.iconName = iconName
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.bold = bold
        self.large = large
        self.label = label
        self.labelOpacity = labelOpacity
        self.action = action
    }
    
    var body: some View {
        Button(
            action: action,
            label: {
                let icon = icon()
                if let text = label {
                    HStack(spacing: 0) {
                        icon
                        
                        Text(text)
                            .opacity(labelOpacity)
                    }
                } else {
                    icon
                }
            }
        )
    }
    
    @ViewBuilder
    private func icon() -> some View {
        ZStack {
            switch(backgroundColor) {
            case .material(material: let material):
                Circle()
                    .fill(material)
                    .frame(width: 30, height: 30)
            case .color(color: let color):
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
            }
            
            let image = Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .scaleEffect(large ? 0.616 : 0.416)
                .foregroundColor(foregroundColor ? .accentColor : .white)
            if(bold) {
                image.font(Font.body.weight(.bold))
            }else {
                image
            }
        }
    }
}

enum SeriesToolbarButtonBackgroundType {
    case material(Material)
    case color(Color)
}
