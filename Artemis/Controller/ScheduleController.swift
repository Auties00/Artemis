//
//  ScheduleController.swift
//   Artemis
//
//  Created by Alessandro Autiero on 18/07/24.
//

import Foundation

@Observable
class ScheduleController {
    var data: AsyncResult<[ScheduleEntry]> = .empty
    
    private let apiController: ApiController
    init(apiController: ApiController) {
        self.apiController = apiController
    }
    
    var notifications: Bool {
        get {
            access(keyPath: \.notifications)
            return UserDefaults.standard.bool(forKey: "simulcastsNotifications")
        }
        set {
            withMutation(keyPath: \.notifications) {
                UserDefaults.standard.setValue(newValue, forKey: "simulcastsNotifications")
            }
        }
    }
    
    func loadData() async {
        do {
            let isRefresh = data.value != nil
            let startTime = Date.now.millisecondsSince1970
            
            if(isRefresh) {
                self.data = .loading
            }
            
            let encodedTimeZone = TimeZone.current.identifier.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            let result: ScheduleResponse = try await self.apiController.sendRequest(
                method: "GET",
                path: "v1/view/schedule?timezone=\(encodedTimeZone)&groupsPerPage=7&itemsPerGroup=7"
            )
            
            if(isRefresh) {
                let sleepTime = 750 - (Date.now.millisecondsSince1970 - startTime)
                if sleepTime > 0 {
                    try? await Task.sleep(for: .milliseconds(sleepTime))
                }
            }
            
            self.data = .success(getCards(data: result))
        }catch let error {
            data = .error(error)
        }
    }
    
    private func getCards(data: ScheduleResponse) -> [ScheduleEntry] {
        for element in data.elements {
            if case .groupList(let scheduleElement) = element {
                return scheduleElement
                    .attributes
                    .groups
                    .lazy
                    .flatMap { $0.attributes.cards ?? [] }
                    .compactMap { getScheduleEntry(entry: $0) }
            }
        }
        
        return []
    }
    
    // Parsing this data is kind of hard
    private func getScheduleEntry(entry: ScheduleElementGroupCard) -> ScheduleEntry? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy-MM-dd'T'HH:mm"
        
        var date: String?
        var seriesTitle: String?
        var episodeTitle: String?
        var episodeType: String?
        
        for element in entry.attributes.content {
            if case .gridBlock(let scheduleElementGroupCardContent) = element {
                for child in scheduleElementGroupCardContent.attributes.elements {
                    switch(child) {
                    case .textBlock(let textBlock):
                        let text = textBlock.attributes.text
                        if textBlock.attributes.format == "date-time" {
                            date = dateFormatter.date(from: text)?.toRelativeString(includeHour: true) ?? text
                            if(seriesTitle != nil && episodeTitle != nil && episodeType != nil) {
                                break
                            }
                        }else if(textBlock.attributes.format == nil) {
                            let titleParts = text.split(separator: " - ", maxSplits: 2)
                            episodeTitle = String(titleParts[0])
                            seriesTitle = titleParts.count != 2 ? "" : String(titleParts[1])
                            if(date != nil && episodeType != nil) {
                                break
                            }
                        }
                    case .tagList(let tagList):
                        for tag in tagList.attributes.tags {
                            if case .tag(let tagElement) = tag {
                                episodeType = tagElement.attributes.text.attributes.text
                                if(seriesTitle != nil && episodeTitle != nil && date != nil) {
                                    break
                                }
                            }
                        }
                    default:
                        break
                    }
                }
            }
        }
        
        guard let date = date, let seriesTitle = seriesTitle, let episodeTitle = episodeTitle, let episodeType = episodeType else {
            return nil
        }
        
        guard let thumbnail = entry.attributes.header.first?.attributes.source else {
            return nil
        }
        
        return ScheduleEntry(
            id: entry.attributes.action.data.id,
            thumbnail: thumbnail,
            date: date,
            seriesTitle: seriesTitle,
            episodeTitle: episodeTitle,
            episodeType: episodeType
        )
    }
}
