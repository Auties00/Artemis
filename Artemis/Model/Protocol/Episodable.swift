//
//  Playable.swift
//  Hidive
//
//  Created by Alessandro Autiero on 22/07/24.
//

import Foundation

protocol Episodable: Descriptable {
    var posterUrl: ThumbnailEntry? {
        get
    }
    
    var episodes: [Episode]? {
        get
        set
    }
    
    var paging: Paging? {
        get
    }
    
    var isSaved: Bool {
        get
    }
}
