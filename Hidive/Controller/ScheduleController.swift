//
//  ScheduleController.swift
//  Hidive
//
//  Created by Alessandro Autiero on 18/07/24.
//

import Foundation

private let endpoint: String = "https://animeschedule.net/api/v3/timetables/all"
private let clientToken: String = "5hLYWRKSKrR783eqIfF71rspSE7IPP"

@Observable
class ScheduleController: ObservableObject {
    private let apiController: ApiController
    private let decoder: JSONDecoder
    var data: AsyncResult<[ScheduleBucketEntry]>
    init(apiController: ApiController) {
        self.apiController = apiController
        self.decoder = JSONDecoder()
        self.data = .loading
    }
    
    public func loadData() async {
        do {
            let calendar = Calendar.current
            let date = Date(timeIntervalSinceNow: 0)
            let year = calendar.component(.year, from: date)
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            let timezone = TimeZone.current.identifier
            guard let url = URL(string: "\(endpoint)?week=\(weekOfYear)&year=\(year)&tz=\(timezone)") else {
                throw RequestError.invalidUrl
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = [
                "Authorization": "Bearer \(clientToken)"
            ]
            
            guard let (responseBody, response) = try? await URLSession.shared.data(for: request) else {
                throw RequestError.invalidConnection
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if(httpResponse.statusCode != 200) {
                    throw RequestError.invalidResponseData()
                }
            }
            
            guard let result = try? decoder.decode(ScheduleResponse.self, from: responseBody) else {
                throw RequestError.invalidResponseData()
            }
            
            let scheduleEntries = result.entries
                .filter { $0.airType != "raw" && $0.streams["hidive"] != nil}
            
            try await withThrowingTaskGroup(of: ScheduleBucketEntry.self) { group in
                for scheduleEntry in scheduleEntries {
                    group.addTask {
                        do {
                            let stream = URL(string: "https://\(scheduleEntry.streams["hidive"]!)")!
                            var request = URLRequest(url: stream)
                            request.httpMethod = "GET"
                            let (_, response) = try await URLSession.shared.data(for: request)
                            let urlParts = response.url!.absoluteString.split(separator: "/")
                            let season: Season = try await self.apiController.sendRequest(
                                method: "GET",
                                path: "v4/\(urlParts[urlParts.count - 2])/\(urlParts[urlParts.count - 1])?rpp=20",
                                log: true
                            )
                            return ScheduleBucketEntry(scheduleEntry: scheduleEntry, season: season)
                        }catch let error {
                            throw error
                        }
                    }
                }
                
                var scheduleBucketEntries = [ScheduleBucketEntry]()
                
                for try await scheduleBucketEntry in group {
                    scheduleBucketEntries.append(scheduleBucketEntry)
                }
                
                data = .success(scheduleBucketEntries.sorted { $1.scheduleEntry.episodeDate > $0.scheduleEntry.episodeDate })
            }
            
        }catch let error {
            data = .failure(error)
        }
    }
}
