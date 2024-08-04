//
//  HomeView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 08/07/24.
//

import SwiftUI
import ACarousel

struct HomeView: View {
    @ObservedObject
    private var accountController: AccountController
    
    init(accountController: AccountController) {
        self.accountController = accountController
    }
    
    var body: some View {
        TabNavigationView(title: "Home") {
            GeometryReader { geometry in
                List {
                    switch(accountController.dashboard) {
                    case .empty, .loading:
                        ExpandedView(geometry: geometry) {
                            LoadingView()
                        }
                    case .success(data: let data):
                        HeroCarouselView(heroes: data.heroes)
                        
                        ForEach(data.buckets) { bucket in
                            BucketSectionView(bucket: bucket)
                        }
                    case .failure(error: let error):
                        ExpandedView(geometry: geometry) {
                            ErrorView(error: error)
                        }
                    }
                }
            }
        }
    }
}
