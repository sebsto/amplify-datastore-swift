//
//  UserData.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 06/11/2022.
//

import Combine
import SwiftUI

//@MainActor
final class UserData: ObservableObject {
    @Published var podcast : [Podcast] = []
    @Published var selectedPodcast : Podcast?
    
    static private(set) var shared = UserData()
    
    private init() {}
    
    static func shared(podcastList: [Podcast], selectedPodcast: Podcast) -> UserData {
        shared.podcast = podcastList
        shared.selectedPodcast = selectedPodcast
        return shared
    }
    
    func clear() {
        self.podcast = []
        self.selectedPodcast = nil
    }
}
