//
//  UserData.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 06/11/2022.
//

import Combine
import SwiftUI

final class UserData: ObservableObject {
    @Published var podcast : [Podcast] = []
    @Published var selectedPodcast : Podcast?
    
    init() {}
    
    init(podcastList: [Podcast], selectedPodcast: Podcast) {
        self.podcast = podcastList
        self.selectedPodcast = selectedPodcast
    }
    
    func clear() {
        self.podcast = []
        self.selectedPodcast = nil
    }
}
