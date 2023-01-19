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

extension MainView {
    @MainActor
    final class ViewModel: ObservableObject {
        
        // state of the UI for each category and podcast
        @Published var podcastState : [Podcast.Category : State<[Podcast]>] = [:]
        @Published var episodeState : [Podcast.ID : State<[Podcast.Episode]>] = [:]
        
        private var backend = Backend()
        
        enum State<T> {
            case noData
            case loading
            case dataAvailable(T)
            case error(Error)
        }
        
        func loadPodcasts(for category: Podcast.Category) async {
            
            // when we did not load podcast for this category yet
            print("Loading podcast for \(category)")
            self.podcastState[category] = .loading
            
            //            // the callback version
            //            self.backend.loadPodcast(for: category) { result in
            //                switch(result) {
            //                case .success(let podcastData):
            //                    print("Podcast callback yielded \(podcastData.count) results")
            //                    let result = self.convertDataToModel(podcastData: podcastData)
            //                    self.podcastState[category] = .dataAvailable(result)
            //                case .failure(let error):
            //                    self.podcastState[category] = .error(error)
            //                }
            //            }

            // the asyncstream version
            do {
                for try await data in self.backend.loadPodcast(for: category) {
                    print("==== PODCAST LOOP yielded \(data.count) results")
                    let result = convertDataToModel(podcastData :data)
                    self.podcastState[category] = .dataAvailable(result)
                }
                print("==== EXITED PODCAST LOOP =====")
            } catch {
                self.podcastState[category] = .error(error)
            }
        }
        
        // convert backend data to UI data
        func convertDataToModel(podcastData : [PodcastData]) -> [Podcast] {
            var result : [Podcast] = []
            for pd in podcastData {
                result.append(Podcast(from: pd))
            }
            return result
        }
        
        func loadEpisodes(for podcast: Podcast) async  {
            
            print("Loading episodes for \(podcast.id)")
            
            episodeState[podcast.id] = . loading
            
            //         // the callback version
            //        self.backend.loadEpisodes(for: podcast) { result in
            //            switch(result) {
            //            case .success(let data):
            //                print("Episode callback yielded \(data.count) values")
            //                let result = self.convertDataToModel(episodeData: data)
            //                self.episodeState[podcast.id] = .dataAvailable(result)
            //            case .failure(let error):
            //                self.episodeState[podcast.id] = .error(error)
            //
            //            }
            //        }
            
            // the AsyncStream version
            do {
                for try await data in self.backend.loadEpisodes(for: podcast) {
                    print("==== EPISODE LOOP yielded \(data.count) results")
                    let result = convertDataToModel(episodeData: data)
                    self.episodeState[podcast.id] = .dataAvailable(result)
                }
                print("==== EXITED EPISODE LOOP =====")
            } catch {
                self.episodeState[podcast.id] = .error(error)
            }
        }
        
        // create an array of Podcast.Episode
        func convertDataToModel(episodeData: [EpisodeData]) -> [Podcast.Episode] {
            var result : [Podcast.Episode] = []
            for e in episodeData {
                result.append(Podcast.Episode(from: e))
            }
            return result
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
    }
}
