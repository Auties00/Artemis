//
//  BucketSectionView.swift
//  Hidive
//
//  Created by Alessandro Autiero on 17/07/24.
//

import SwiftUI

struct BucketSectionView: View {
    private let bucket: Bucket
    init(bucket: Bucket) {
        self.bucket = bucket
    }
    
    var body: some View {
        Section(header: Text(toBucketTitle(input: bucket.name))) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(bucket.contentList!) { contentEntry in
                        NavigationLink(value: PageType.season(contentEntry)) {
                            VStack(alignment: .leading) {
                                NetworkImage(url: contentEntry.coverUrl!)
                                    .frame(width: 250, height: 150)
                                
                                Text(contentEntry.title!)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 250)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func toBucketTitle(input: String?) -> String {
        guard let input = input else {
            return ""
        }
        
        return input.split(separator: " ")
            .map { $0.lowercased().capitalized }
            .joined(separator: " ")
    }
}
