//
//  EpisodeView.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 06/11/2022.
//

import SwiftUI

struct EpisodeView: View {

    let podcast : Podcast
    let episode : Podcast.Episode

    var body: some View {

        HStack(alignment: .center, spacing: 10) {
            ImageStore.shared.image(name: podcast.image!)
                .resizable()
                .scaledToFit()
                .cornerRadius(5)

            VStack(alignment:.leading) {
                Text(episode.date)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(episode.title)
                Text(episode.description!)
                    .font(.footnote)
                    .truncationMode(.tail)
                    .foregroundColor(.gray)
                Spacer()

                HStack(alignment: .center) {
                    Image(systemName: "play.circle")
                        .foregroundColor(.accentColor)
                    Text(displayDuration(episode.duration))
                        .font(.footnote)
                    Spacer()
                    Image(systemName: "ellipsis")
                    
                }
            }
        }
        .frame(width: nil, height: 80)
//            .padding()
    }
    
    // 01:18:35 -> 1h 18min
    func displayDuration(_ duration: String?) -> String {
        guard let duration else {
            return "0 min"
        }
        
        let elements = duration.split(separator: ":")
        if elements[0] != "00" {
            return "\(elements[0])h \(elements[1])min"
        } else {
            return "\(elements[1])min"
        }
    }
}

struct EpisodeView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        let podcast = podcast[0]
        let episode = podcast.episodes![0]
        
        EpisodeView(podcast: podcast, episode: episode)
    }
}
