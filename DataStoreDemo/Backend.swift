//
//  Backend.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 05/11/2022.
//

import Foundation
import Combine
import Amplify
import AWSDataStorePlugin
import AWSAPIPlugin

// to generate random text
import LoremSwiftum

/**
 
 I used amplify overrides to set the TTL on delta table to one week.
 https://docs.amplify.aws/cli/graphql/override/#customize-amplify-generated-resources-for-model-directive
 https://github.com/aws-amplify/amplify-category-api/issues/47#issuecomment-1129351690
 
 The CDK override has one line
 ```
 resources.models['EpisodeData'].modelDatasource.dynamoDbConfig['deltaSyncConfig']['deltaSyncTableTtl'] = '10080'
 ```
 
 When the app starts, it will fetch all changes since the last week.
 One improvement from the app would be to check the last sync time.  When it is longer than TTL, perform a full sync (clean and load)
 
 */
class Backend {
    
    public let userData : UserData = UserData()
    
    // declare a cancellable to hold onto the subscription
    private(set) var episodeSubscription: [String:AnyCancellable] = [:]
    private(set) var podcastSubscription: [Podcast.Category:AnyCancellable] = [:]
    
    static var shared = Backend()
    private init() {
        do {
            
            // AmplifyModels is generated in the previous step
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels())
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure()
//            Amplify.Logging.logLevel = .verbose
            print("Amplify configured with DataStore plugin")
            
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }

        listenAmplifyDataStoreEvent()
    }
    
    func listenAmplifyDataStoreEvent() {
        let _ = Amplify.Hub.listen(to: .dataStore) { event in
            
            print("User receives datastore event: \(event.eventName)")
            if let data = event.data {
                print("\(String(describing: data))")
            }
            
            if event.eventName == HubPayload.EventName.DataStore.networkStatus {
                guard let networkStatus = event.data as? NetworkStatusEvent else {
                    print("Failed to cast data as NetworkStatusEvent")
                    return
                }
                if networkStatus.active {
                    Task {
                        print("Network connection is up, start syncing")
                    }
                } else {
                    Task {
                        print("Network connection is down, stop syncing")
                    }
                }
            }
        }
    }
    
    //MARK: Methods called by the GUI
    
    func podcastCategories() -> [Podcast.Category] {
        return Podcast.Category.allCases
    }
    
    // load podcast and update GUI
    // when userData.podcast is updated, the GUI refreshes
    func loadPodcastForGUI(for category: Podcast.Category) async -> [Podcast] {
        
        // load podcasts and subscribe to changes
        
        // https://docs.amplify.aws/lib/datastore/real-time/q/platform/ios/#observe-query-results-in-real-time
        let p = PodcastData.keys
        self.podcastSubscription[category] = Amplify.Publisher.create(
            Amplify.DataStore.observeQuery(for: PodcastData.self,
                                           where: p.category == PodcastCategoryData(from: category))
        )
        
        // this runs on the main thread because it updates the GUI
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Subscription received error - \(error)")
                }
            },
            receiveValue: { querySnapshot in
                print("[Podcast snapshot] item count: \(querySnapshot.items.count), isSynced: \(querySnapshot.isSynced)")
                //                //wait for podcast to be loaded from the network (isSynced == true)
                //                guard querySnapshot.isSynced == true else { return }
                
                var result : [Podcast] = []
                for p in querySnapshot.items {
                    result.append(Podcast(from: p))
                }
//                print(result)
                self.userData.podcast = result
            })
        
        return self.userData.podcast
    }
    
    // load episodes for one podcast and update GUI
    // when userData.podcast is updated, the GUI refreshes
    func loadEpisodesForGUI(for podcast: Podcast) async -> Podcast {

        // load episodes
        let e = EpisodeData.keys
        
        self.episodeSubscription[podcast.id] = Amplify.Publisher.create(
            Amplify.DataStore.observeQuery(for: EpisodeData.self,
                                           where: e.podcastDataEpisodesId == podcast.id)
        )
        
        // this runs on the main thread because it updates the GUI
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Subscription received error - \(error)")
                }
            },
            receiveValue: { querySnapshot in
                print("[Episode snapshot] item count: \(querySnapshot.items.count), isSynced: \(querySnapshot.isSynced)")
                //                //wait for episodes to be loaded from the network (isSynced == true)
                //guard querySnapshot.isSynced == true else { return }
                
                // create an array of Podcast.Episode
                var result : [Podcast.Episode] = []
                for e in querySnapshot.items {
                    result.append(Podcast.Episode(from: e))
                }
//                print(result)
                
                // find the matching podcast in the user data and replace with
                // a podcast with the updated [Epispde]
                var allPodcast = self.userData.podcast
                if let i = allPodcast.firstIndex(where: { p in p.id == podcast.id }) {
                    allPodcast[i].episodes = result
                } else {
                    // a new episde has been added
                    print("Can not find podcast in userData")
                }
                // replace the entire array of podcast to trigger the GUI refresh
                self.userData.podcast = allPodcast
            })
        
        return podcast
    }
    
    func mutateEpisodeList(for podcast: Podcast) async throws -> Podcast {
        
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let min = Calendar.current.component(.minute, from: now)
        let sec = Calendar.current.component(.second, from: now)
        let newEpisode = Podcast.Episode(id: UUID().uuidString,
                                         date: Date().formatted(date: .abbreviated, time: .omitted),
                                         title: "[NEW] \(Lorem.words(3))",
                                         duration: "\(hour):\(min):\(sec)",
                                         description: "\(Lorem.paragraph)")
        
        do {
            print("Adding episode \(newEpisode.title)")
            var episodeData = EpisodeData(from: newEpisode)
            episodeData.podcastDataEpisodesId = podcast.id
            try await Amplify.DataStore.save(episodeData)
            print("Created a new episode successfully")
        } catch let error as DataStoreError {
            print("Error creating podcast - \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
        
        return podcast
    }
    
    func deleteEpisode(episode: Podcast.Episode) async {
        
        do {
            // https://docs.amplify.aws/lib/datastore/data-access/q/platform/ios/#delete
            
            // we don't have a full EpisodePodcastData here, just an Podcast.Episode.
            // so I am using the delete with ID
            print("Deleteing episode \(episode.title)")
            try await Amplify.DataStore.delete(EpisodeData.self, withId: episode.id)
            print("Deleting was succesful")
            
            // the local cache will be refreshed automatically
            // this will trigger the reload of the UI
            
        } catch let error as DataStoreError {
            print("Error deleting episode - \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
        
    }
    
    //MARK: methods to call the datastore
    
    @MainActor
    func clearLocalData() async throws {
        try await Amplify.DataStore.clear()
    }
    
    //MARK:  Methods not used
    // used once to import data to the datastore and backend
    func importPodcast() async throws {
        
        // import local JSON data to the backend
        
        for p in DataStoreDemo.podcast {
            print("Handling podcast : \(p.name)")
            do {
                let podcastData = PodcastData(from: p)
                try await Amplify.DataStore.save(podcastData)
                print("Created a new podcast successfully")
            } catch let error as DataStoreError {
                print("Error creating post - \(error)")
            } catch {
                print("Unexpected error \(error)")
            }
        }
    }
    
    // used once to import data to the datastore and backend
    func importEpisode() async throws {
        // import local JSON data to the backend
        
        for p in DataStoreDemo.podcast {
            print("Handling podcast : \(p.name)")
            let podcastID = p.id
            
            if let episodes = p.episodes {
                for e in episodes {
                    do {
                        print("Handling episode \(e.title)")
                        var episodeData = EpisodeData(from: e)
                        episodeData.podcastDataEpisodesId = podcastID
                        try await Amplify.DataStore.save(episodeData)
                        print("Created a new episode successfully")
                    } catch let error as DataStoreError {
                        print("Error creating post - \(error)")
                    } catch {
                        print("Unexpected error \(error)")
                    }
                }
            }
        }
    }
    
}

