//
//  Playable.swift
//  Hidive
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

protocol Episodable {
    var title: String {
        get
    }
    
    var description: String {
        get
    }
    
    var episodes: [Episode]? {
        get
    }
}
