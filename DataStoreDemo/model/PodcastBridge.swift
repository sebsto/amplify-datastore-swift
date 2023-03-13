//
//  PodcastDataBridge.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 06/11/2022.
//

import Foundation

//MARK: from API model to app model
extension Podcast.Episode {
    init(from episode: EpisodeData) {
        self.id          = episode.id
        self.date        = episode.date
        self.title       = episode.title
        self.duration    = episode.duration
        self.description = episode.description
    }
}
extension Podcast.Category {
    init(from category: PodcastCategoryData) {
        switch category {
        case .cloud:
            self = .cloud
        case .comedy:
            self = .comedy
        case .technology:
            self = .technology
        }
    }
}
extension Podcast {
    init(from podcast: PodcastData) {
        
        self.id   = podcast.id
        self.name = podcast.name
        self.category = .init(from: podcast.category)
        self.author = podcast.author
        self.rating = podcast.rating
        self.image  = podcast.image
        
        // do not handle episodes, they are loaded on-demand
        self.episodes = []
        
        //        if let episodes = podcast.episodes {
        //            self.episodes = episodes.map { e in
        //                return Episode(from: e)
        //            }
        //        } else {
        //            self.episodes = nil
        //        }
        
    }
}

//MARK: from app model to API model
extension EpisodeData {
    
    init(from episode: Podcast.Episode) {
        self.id          = episode.id
        self.date        = episode.date
        self.title       = episode.title
        self.duration    = episode.duration
        self.description = episode.description
    }
    
}

extension PodcastCategoryData {
    init(from category: Podcast.Category) {
        switch category {
        case .cloud:
            self = .cloud
        case .comedy:
            self = .comedy
        case .technology:
            self = .technology
        }
    }
}
extension PodcastData {
    
    init(from podcast: Podcast) {
        
        self.id   = podcast.id
        self.name = podcast.name
        
        switch podcast.category {
        case .cloud:
            self.category = .cloud
        case .comedy:
            self.category = .comedy
        case .technology:
            self.category = .technology
        }
        
        self.author = podcast.author
        self.rating = podcast.rating
        self.image  = podcast.image
        
        
        // do not handle episodes, they will be added one by one at save time
    }
    
}
