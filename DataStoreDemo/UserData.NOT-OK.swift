//
//  UserData.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 06/11/2022.
//

import Combine
import SwiftUI

@MainActor
final class UserData: ObservableObject {
    @Published private(set) var podcasts : [Podcast] = []
    
    // not private(set) because the List view modifies these
    @Published var selectedPodcast : Podcast? = nil
    @Published var selectedCategory : Podcast.Category? = .cloud

    private var selectedCategorySubscription: AnyCancellable? = nil
    private var selectedPodcastSubscription: AnyCancellable? = nil

    static private(set) var shared = UserData()
    
    private init() {
        
        // manage the reload of data when category or podcast selection changes
        
        selectedCategorySubscription = $selectedCategory.sink(receiveValue: { newValue in
//            print("============")
//            print("New Value \(newValue)")
//            print("Old Value \(self.selectedCategory?.name)")
//            print("============")
            // reload podcast for this category and reset episode state
            if let c = newValue {
                self.episodeState = .noData
                Task {
                    //force data refresh for this category (tip can improve by caching data ?)
                    await self.loadPodcasts(for: c)
                }
            }
        })
        selectedPodcastSubscription = $selectedPodcast.sink(receiveValue: { newValue in
//            print("============")
//            print("New Value \(newValue)")
//            print("Old Value \(self.selectedPodcast?.description())")
//            print("============")

            // warning this method might be called twice when category changes
            // reload epiosdes for this podcast (when one is selected)d
            if let p = newValue {
                
                // sonetime this method is called twice - be sure to not reload episode in that case
                if (p != self.selectedPodcast) {
                    Task {
                        //force episode refresh for this podcast (tip can improve by caching data ?)
                        await self.loadEpisodes(for: p)
                    }
                }
            }
        })
    }
    
    static func shared(podcastList: [Podcast], selectedPodcast: Podcast) -> UserData {
        shared.podcasts = podcastList
        shared.selectedPodcast = selectedPodcast
        return shared
    }
    
    enum State<T> {
        case noData
        case loading
        case dataAvailable(T)
        case error(Error)
    }
    @Published private(set) var podcastState : State<[Podcast]> = .noData
    @Published private(set) var episodeState : State<Podcast> = .noData
    
    func loadPodcasts(for category: Podcast.Category) async {

        print("====== loading podcast for \(category)")
        do {
            podcastState = .loading

            // continuously load podcasts from backend
            for try await podcasts in Backend.shared.loadPodcast(for: category) {
                print("===== podcast subscription yielded new values")
                // convert backend data to UI data
                var result : [Podcast] = []
                for p in podcasts {
                    result.append(Podcast(from: p))
                }
                self.podcastState = .dataAvailable(result) //TODO: apply changes only ?
                if result.count > 0 {
                    self.selectedPodcast = result[0]
                }
            }
            
        } catch {
            podcastState = .error(error)
        }
    }
    
    func loadEpisodes(for podcast: Podcast) async -> Podcast {
        
        print("loading episodes for \(podcast)")

        var newPodcast = Podcast(from: podcast)
        
                 do {
                     episodeState = .loading
        
                     // load episodes from backend
                     for try await episodes in Backend.shared.loadEpisodes(for: podcast) {
                         print("===== episode subscription yielded new \(episodes.count) values")

                         // create an array of Podcast.Episode
                         var result : [Podcast.Episode] = []
                         for e in episodes {
                             result.append(Podcast.Episode(from: e))
                         }
                         
                         newPodcast.episodes = result
//                         print(newPodcast)
                         episodeState = .dataAvailable(newPodcast)
                     }
        
                 } catch {
                     episodeState = .error(error)
                 }
        return newPodcast
    }
    
    func podcastCategories() -> [Podcast.Category] {
        return Podcast.Category.allCases
    }
    
    func clear() {
        self.podcasts = []
        self.selectedPodcast = nil
    }
    
    static func mock() -> UserData {
        let userData = UserData()
        userData.podcasts = .mock
        userData.podcastState = .dataAvailable(userData.podcasts)
        userData.episodeState = .dataAvailable(.mock)
        userData.selectedPodcast = .mock
        return userData
    }
}
