//
//  AnimeController.swift
//  Hidive
//
//  Created by Alessandro Autiero on 21/07/24.
//

import Foundation

private let endpoint: String = "https://h99xldr8mj-dsn.algolia.net/1/indexes/*/queries?x-algolia-agent=Algolia%20for%20JavaScript%20(3.35.1)%3B%20Browser&x-algolia-application-id=H99XLDR8MJ&x-algolia-api-key=e55ccb3db0399eabe2bfc37a0314c346"

@Observable
class SearchController {
    private var apiController: ApiController
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    var categories: AsyncResult<[CategorySectionLink]> = .empty
    
    init(apiController: ApiController) {
        self.apiController = apiController
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }
    
    func search(query: String) async throws -> [SearchEntry]? {
        if(query.isEmpty) {
            return nil
        }
        
        guard let url = URL(string: endpoint) else {
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
                    "params": "query=\(urlEncodedQuery)&facetFilters=%5B%22type%3AVOD_SERIES%22%5D&hitsPerPage=5"
                ],
                [
                    "indexName": "prod-dce.hidive-livestreaming-events",
                    "params": "query=\(urlEncodedQuery)&facetFilters=%5B%22type%3AVOD_PLAYLIST%22%5D&hitsPerPage=5"
                ]
            ]
        ]
        request.httpBody = try encoder.encode(params)
        let (responseBody, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if(httpResponse.statusCode != 200) {
                throw RequestError.invalidResponseStatusCode(httpResponse.statusCode)
            }
        }
        
        let responseData = try decoder.decode(SearchResponse.self, from: responseBody)
        return responseData.results
    }
    
    
    func loadCategories() async {
        do {
            categories = .loading
            let result: CategoriesResponse = try await apiController.sendRequest(
                method: "GET",
                path: "v4/content/browse?bpp=10&rpp=12&displaySectionLinkBuckets=SHOW&displayEpgBuckets=HIDE&displayEmptyBucketShortcuts=SHOW&displayContentAvailableOnSignIn=SHOW&displayGeoblocked=SHOW&bspp=20"
            )
            guard let genres = result.buckets.first(where: { $0.name.localizedCaseInsensitiveContains("Genres")}) else {
                categories = .error(CategoriesError.missingData)
                return
            }
            
            let categories = genres.contentList.compactMap {
                switch($0) {
                case .sectionLink(let sectionLink):
                    return sectionLink
                default:
                    return nil
                }
            }
            self.categories = .success(categories)
        }catch let error {
            categories = .error(error)
        }
    }
}
