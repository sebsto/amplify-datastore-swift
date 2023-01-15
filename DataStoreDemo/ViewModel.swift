//
//  UserData.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 06/11/2022.
//

import Combine
import SwiftUI

@MainActor
final class ViewModel: ObservableObject {

    // state of the UI for each category and podcast
    @Published private(set) var podcastState : [Podcast.Category : State<[Podcast]>] = [:]
    @Published private(set) var episodeState : [Podcast.ID : State<[Podcast.Episode]>] = [:]
    
    private var backend = Backend()

    enum State<T> {
        case noData
        case loading
        case dataAvailable(T)
        case error(Error)
    }
    
    func loadPodcasts(for category: Podcast.Category) async {

        // when we did not load podcast for this category yet
            print("====== loading podcast for \(category)")
            do {
                self.podcastState[category] = .loading
                
                
//                let podcastData = try await Backend.shared.loadPodcast(for: category)
                for try await podcastData in backend.loadPodcast(for: category) {
                    print("===== podcast subscription yielded new \(podcastData.count) values")
                    
                    var result : [Podcast] = []
                    // convert backend data to UI data
                    for pd in podcastData {
                        result.append(Podcast(from: pd))
                    }
                    self.podcastState[category] = .dataAvailable(result)
                }
                
//                print("===== Exited podcast loop with state \(self.podcastState[category])")
                if case .loading = self.podcastState[category]  {
                    self.podcastState[category] = .noData
                }
            } catch {
                podcastState[category] = .error(error)
            }
    }
  
    func loadEpisodes(for podcast: Podcast) async  {
        
        print("====== loading episodes for \(podcast)")
                    
        do {
            episodeState[podcast.id] = . loading
            
            // load episodes from backend
//                let episodeData = try await Backend.shared.loadEpisodes(for: podcast)
            for try await episodeData in backend.loadEpisodes(for: podcast) {
                print("===== episode subscription yielded new \(episodeData.count) values")

                // create an array of Podcast.Episode
                var result : [Podcast.Episode] = []
                for e in episodeData {
                    result.append(Podcast.Episode(from: e))
                }

                // refresh the view if the update is for the currently selected podcast
                    self.episodeState[podcast.id] = .dataAvailable(result)
            }
            print("===== Exited episode loop")

        } catch {
            episodeState[podcast.id] = .error(error)
        }

    }
    
    func podcastCategories() -> [Podcast.Category] {
        return Podcast.Category.allCases
    }
    
    func reload() {
        print("Reload from datastore")
        self.episodeState = [:]
        self.podcastState = [:]
    }
    
    func clearLocalData() {
        print("Clear datastore local data")
        Task {
            try await backend.clearLocalData()
        }
    }
    
    func addEpisode(for podcast:Podcast) {
        print("Add episode")
        // TODO
//        if let pod = selectedPodcast {
//            let _ = try await Backend.shared.mutateEpisodeList(for: pod )
//        }
        
        // + update datavailable

    }
    
    func deleteEpisode(_ episode : Podcast.Episode) {
        guard episode.id.count > 7 else {
            print("let's not delete built-in episodes")
            return
        }
        
        //call backend on background to delete episode and refresh UI
        Task {
            await backend.deleteEpisode(episode: episode)
        }
        
        //TODO update .dataAvailable
    }
    
    static func mock() -> ViewModel {
        let viewModel = ViewModel()
        viewModel.podcastState[Podcast.Category.cloud] = .dataAvailable(.mock)
        return viewModel
    }
}
