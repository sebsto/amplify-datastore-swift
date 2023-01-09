//
//  PodcastView.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 06/11/2022.
//

import SwiftUI

struct PodcastView: View {
    let podcast : Podcast
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if let image = podcast.image {
                ImageStore.shared.image(name: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(10)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(podcast.name)
                    .font(.system(.title3, design: .rounded))
                    .bold()
                Text("By \(podcast.author)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: nil, height: 50, alignment: .leading)
//        .border(.red)
    }
}

struct PodcastView_Previews: PreviewProvider {
    static var previews: some View {
        PodcastView(podcast: .mock)
    }
}
