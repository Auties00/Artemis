//
//  iPhoneDimensions.swift
//  Hidive
//
//  Created by Alessandro Autiero on 11/07/24.
//

import Foundation
import SwiftUI

extension View {
    var horizontalPaddingAddend: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        if screenHeight * UIScreen.main.nativeScale >= 896 * 3 || screenHeight == 736 { // iPhone pro max, iPhone plus
            return 20
        } else if screenHeight == 568 { // iPhone SE 1st gen
            return -10
        } else { // The rest
            return 0
        }
    }
}
