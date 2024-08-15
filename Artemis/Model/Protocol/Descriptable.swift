//
//  Descriptable.swift
//  Hidive
//
//  Created by Alessandro Autiero on 25/07/24.
//

import Foundation

protocol Descriptable {
    var id: Int {
        get
    }
    
    var parentId: Int {
        get
    }
    
    var coverUrl: ThumbnailEntry? {
        get
    }
    
    var title: String {
        get
    }
    
    var parentTitle: String {
        get
    }
    
    var description: String {
        get
    }
    
    var longDescription: String {
        get
    }
}
