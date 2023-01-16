//
//  PodcastMock.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 09/01/2023.
//

import Foundation

extension Array<Podcast> {
    
    static var mock : [Podcast] = load("podcast.json")

    static func load<T: Decodable>(_ filename: String) -> T {
        let data: Data
        
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
            else {
                fatalError("Couldn't find \(filename) in main bundle.")
        }
        
        do {
            data = try Data(contentsOf: file)
        } catch {
            fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
        }
    }
}

extension Podcast {
    static var mock : Podcast = [Podcast].mock[0]
}

extension ViewModel {
    static var mock : ViewModel = mockedData()
    
    fileprivate static func mockedData() -> ViewModel {
        let vm = ViewModel()
        
        // populate podcast for all categories 
        for c in Podcast.Category.allCases {
            let podcast = [Podcast].mock.filter({ p in
                p.category == c
            })
            vm.podcastState[c] = .dataAvailable(podcast)
        }
        
        // populate episode data for all podcast
        for p in [Podcast].mock {
            vm.episodeState[p.id] = .dataAvailable(p.episodes)
        }
        
        return vm
    }
}
