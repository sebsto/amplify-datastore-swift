//
//  UserData.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 06/11/2022.
//

//import Combine
import SwiftUI

// to generate random text when creating episodes
import LoremSwiftum

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
                
                self.backend.loadPodcast(for: category) { podcastData in
                    print("===== podcast callback yielded new \(podcastData.count) values")
                    
                    var result : [Podcast] = []
                    // convert backend data to UI data
                    for pd in podcastData {
                        result.append(Podcast(from: pd))
                    }
                    self.podcastState[category] = .dataAvailable(result)
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
            self.backend.loadEpisodes(for: podcast) { episodeData in
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
        print("Going to add episode")
        
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let min = Calendar.current.component(.minute, from: now)
        let sec = Calendar.current.component(.second, from: now)
        let newEpisode = Podcast.Episode(id: UUID().uuidString,
                                         date: Date().formatted(date: .abbreviated, time: .omitted),
                                         title: "[NEW] \(Lorem.words(3))",
                                         duration: "\(hour):\(min):\(sec)",
                                         description: "\(Lorem.paragraph)")
        Task {
            do {
                print("Adding episode \(newEpisode.title)")
                var episodeData = EpisodeData(from: newEpisode)
                episodeData.podcastDataEpisodesId = podcast.id
                try await self.backend.addEpisode(episodeData)
                print("Created a new episode successfully")
                
                // mutate our model to refresh the view
                if case var .dataAvailable(episodes) = episodeState[podcast.id] {
                    episodes.append(newEpisode)
                    episodeState[podcast.id] = .dataAvailable(episodes)
                }
                
            } catch  {
                print("Error creating episode - \(error)")
            }
        }
    }
    
    func deleteEpisode(_ episode : Podcast.Episode, of podcast: Podcast?) {

        print("Going to delete episode")
        
        guard let p = podcast else {
            print("Can not delete episode \(episode.id) for NIL podcast")
            return
        }
        
        guard episode.id.count > 7 else {
            print("let's not delete built-in episodes")
            return
        }
        
        if case var .dataAvailable(episodes) = episodeState[p.id] {
            //call backend on background to delete episode and refresh UI
            Task.detached(priority: .background) {
                let episodeData = EpisodeData(from: episode)
                await self.backend.deleteEpisode(episode: episodeData)
            }

            // delete episode from our model
            episodes.removeAll(where: { e in e.id == episode.id })
            episodeState[p.id] = .dataAvailable(episodes)
            
        } else {
            print("Can not find list of episodes for podcast id \(p.id)")
        }
    }
    
    static func mock() -> ViewModel {
        let viewModel = ViewModel()
        viewModel.podcastState[Podcast.Category.cloud] = .dataAvailable(.mock)
        return viewModel
    }
}
