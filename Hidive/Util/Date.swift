//
//  Date.swift
//  Hidive
//
//  Created by Alessandro Autiero on 10/08/24.
//

import Foundation

extension Date {
    func toRelativeString(includeHour: Bool) -> String {
        let now = Date.now
        let calendar = Calendar.current
        
        let nowYear = calendar.component(.year, from: now)
        let episodeYear = calendar.component(.year, from: self)
        
        let nowMonth = calendar.component(.month, from: now)
        let episodeMonth = calendar.component(.month, from: self)

        let nowWeek = calendar.component(.weekOfYear, from: now)
        let episodeWeek = calendar.component(.weekOfYear, from: self)
        
        let nowDay = calendar.component(.day, from: now)
        let episodeDay = calendar.component(.day, from: self)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = if(episodeYear != nowYear) {
            "dd/MM/yy\(includeHour ? ", HH:mm" : "")"
        } else if(nowMonth != episodeMonth || (self < now && nowWeek != episodeWeek) || (self > now && (episodeDay - nowDay) >= 7)) {
            "dd/MM\(includeHour ? ", HH:mm" : "")"
        } else {
            "EEEE\(includeHour ? ", HH:mm" : "")"
        }
        
        return dateFormatter.string(from: self)
    }
    
    var millisecondsSince1970:Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}
