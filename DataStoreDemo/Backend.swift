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
        
    // declare a cancellable to hold onto the amplify subscription
    private(set) var episodeSubscription: [String:AnyCancellable] = [:]
    private(set) var podcastSubscription: [Podcast.Category:AnyCancellable] = [:]
    
    init() {
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
    
    // load podcast from local store and subscribe to changes
    // this allows to start with an empty store and received sync data as the local store is updated
//    func loadPodcast(for category: Podcast.Category) -> AsyncThrowingStream<[PodcastData], Error> {
    func loadPodcast(for category: Podcast.Category, callback: @MainActor @escaping (Result<[PodcastData],Error>) -> Void) {

        print("[BACKEND] LOAD PODCAST")
        
        // cancel previous subscription if any
        if let s = self.podcastSubscription[category] {
            print("[BACKEND] Canceling previous subscription for category \(category)")
            s.cancel()
        }

        //TODO:
        // transform callback-based code to async/await stream
        // https://www.avanderlee.com/swift/asyncthrowingstream-asyncstream/

        // load podcasts and subscribe to changes
        // https://docs.amplify.aws/lib/datastore/real-time/q/platform/ios/#observe-query-results-in-real-time
        let p = PodcastData.keys
        self.podcastSubscription[category] = Amplify.Publisher.create(
            Amplify.DataStore.observeQuery(for: PodcastData.self,
                                           where: p.category == PodcastCategoryData(from: category))
        )

        // this runs on the main thread because it updates the GUI
//        .receive(on: DispatchQueue.main)
        .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("[Podcast snapshot] Subscription received error - \(error)")

                        // run on the main thread because it updates the UI
                        Task {
                            await callback(Result.failure(error))
                        }
                    }
                    print("[Podcast snapshot] received completion")
                },
                receiveValue: { querySnapshot in
                    print("[Podcast snapshot] item count: \(querySnapshot.items.count), isSynced: \(querySnapshot.isSynced)")

                    // run on the main thread because it updates the UI
                    Task {
                        await callback(Result.success(querySnapshot.items))
                    }
                })
    }

//    func loadPodcast(for category: Podcast.Category) async throws -> [PodcastData] {
//
//            // load podcasts
//            let p = PodcastData.keys
//            return try await Amplify.DataStore.query(PodcastData.self,
//                                              where: p.category == PodcastCategoryData(from: category))
//    }
//
//    func loadEpisodes(for podcast: Podcast) async throws -> [EpisodeData] {
//
//            // load podcasts
//            let e = EpisodeData.keys
//            return try await Amplify.DataStore.query(EpisodeData.self,
//                                                     where: e.podcastDataEpisodesId == podcast.id)
//    }
    
//    // load episodes from local store and subscribe for updates when backend is updated
//    func loadEpisodes(for podcast: Podcast) -> AsyncThrowingStream<[EpisodeData], Error> {
    func loadEpisodes(for podcast: Podcast, callback: @MainActor @escaping (Result<[EpisodeData],Error>) -> Void) {


        print("[BACKEND] LOAD EPISODES for podcast \(podcast.id)")

        // cancel previous subscription if any
        if let s = self.episodeSubscription[podcast.id] {
            print("[BACKEND] Canceling previous EPISODE subscription for podcast \(podcast)")
            s.cancel()
        }

        //TODO:
        // transform callback-based code to async/await stream
        // https://www.avanderlee.com/swift/asyncthrowingstream-asyncstream/

        // load episodes
        let e = EpisodeData.keys

        self.episodeSubscription[podcast.id] = Amplify.Publisher.create(
            Amplify.DataStore.observeQuery(for: EpisodeData.self,
                                           where: e.podcastDataEpisodesId == podcast.id)
        )

        .sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("[Episode snapshot] Subscription received error - \(error)")
                    
                    // run on the main thread because it updates the UI
                    Task {
                        await callback(Result.failure(error))
                    }
                }
                print("[Episode snapshot] received completion")
            },
            receiveValue: { querySnapshot in
                print("[Episode snapshot] item count: \(querySnapshot.items.count), isSynced: \(querySnapshot.isSynced)")

                // run on the main thread because it updates the UI
                Task {
                    await callback(Result.success(querySnapshot.items))
                }
            })
    }
    
    func addEpisode(_ episode: EpisodeData) async throws  {
        
        do {
            print("[BACKEND] Adding episode \(episode.title)")
            try await Amplify.DataStore.save(episode)
            print("[BACKEND] Created a new episode successfully")
        } catch let error as DataStoreError {
            print("[BACKEND] Error creating podcast - \(error)")
        } catch {
            print("[BACKEND] Unexpected error \(error)")
        }
    }
    
    func deleteEpisode(episode: EpisodeData) async {
        
        do {
            // https://docs.amplify.aws/lib/datastore/data-access/q/platform/ios/#delete
            
            print("[BACKEND] Deleting episode \(episode.id)")
            try await Amplify.DataStore.delete(EpisodeData.self, withId: episode.id)
            print("[BACKEND] Deleting was succesful")
            
        } catch let error as DataStoreError {
            print("[BACKEND] Error deleting episode - \(error)")
        } catch {
            print("[BACKEND] Unexpected error \(error)")
        }
        
    }
    
    //MARK: methods to manipulate the datastore
    
    func clearLocalData() async throws {
        try await Amplify.DataStore.clear()
    }
    
    //MARK:  Methods not used
    // used once to import data to the datastore and backend
    func importPodcast() async throws {
        
        // import local JSON data to the backend
        
        for p in [Podcast].mock {
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
        
        for p in [Podcast].mock {
            print("Handling podcast : \(p.name)")
            let podcastID = p.id
            
            for e in p.episodes {
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

