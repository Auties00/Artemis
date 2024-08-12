//
//  String.swift
//  Hidive
//
//  Created by Alessandro Autiero on 11/08/24.
//

import Foundation

extension String {
    static func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    var capitalized: String {
      return prefix(1).uppercased() + self.lowercased().dropFirst()
    }
}
