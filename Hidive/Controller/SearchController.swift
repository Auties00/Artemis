//
//  AnimeController.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import Foundation

@Observable
class SearchController: ObservableObject {
    var query = ""
    var results: AsyncResult<[SearchEntry]> = .empty
    
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    init() {
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }
    
    func executeSearch() async {
        do {
            if(query.isEmpty) {
                results = .empty
                return
            }
            
            results = .loading
            guard let url = URL(string: "https://h99xldr8mj-dsn.algolia.net/1/indexes/*/queries?x-algolia-agent=Algolia%20for%20JavaScript%20(3.35.1)%3B%20Browser&x-algolia-application-id=H99XLDR8MJ&x-algolia-api-key=e55ccb3db0399eabe2bfc37a0314c346") else {
                throw RequestError.invalidUrl
            }
            
            guard let urlEncodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
                throw RequestError.invalidRequestData()
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let params = [
                "requests": [
                    [
                        "indexName": "prod-dce.hidive-livestreaming-events",
                        "params": "query=\(urlEncodedQuery)&facetFilters=%5B%22type%3AVOD_SERIES%22%5D&hitsPerPage=20"
                    ]
                ]
            ]
            request.httpBody = try encoder.encode(params)
            guard let (responseBody, response) = try? await URLSession.shared.data(for: request) else {
                throw RequestError.invalidConnection
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if(httpResponse.statusCode != 200) {
                    throw RequestError.invalidResponseData()
                }
            }
            
            let responseData = try decoder.decode(SearchResponse.self, from: responseBody)
            results = .success(responseData.results)
        }catch let error {
            results = .failure(error)
        }
    }
}
