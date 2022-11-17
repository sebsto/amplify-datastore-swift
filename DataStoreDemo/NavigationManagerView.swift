//
//  ContentView.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 05/11/2022.
//

import SwiftUI


struct NavigationManagerView: View {
    @State private var sideBarVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var selectedPodcastCategory: Podcast.Category? = .cloud
    @State private var selectedPodcast : Podcast?
    
    @EnvironmentObject private var userData: UserData
    
    var body: some View {
        NavigationSplitView(columnVisibility: $sideBarVisibility) {
            
            PodcastCategoryView(category: Backend.shared.podcastCategories(), selectedCategory: $selectedPodcastCategory)
            
        } content: {
            if let spc = selectedPodcastCategory {
                
                if let podcast = userData.podcast.filter { item in
                    item.category == selectedPodcastCategory
                },
                podcast.count > 0 {
                    
                    PodcastListView(podcast: podcast, selectedPodcast: $selectedPodcast)
                    
                } else {
                    
                    NoDataView(message: "Loading podcasts...") {
                        // this will update userdata
                        _ = await Backend.shared.loadPodcastForGUI(for: spc)
                    }
                }
                
            } else {
                Text("Please select a podcast category")
            }
        } detail: {
            
            // browse userData to force GUI refresh when it changes
            if let sp = userData.podcast.first { p in p.id == selectedPodcast?.id } {
                
                if let episodes = sp.episodes,
                   episodes.count > 0 {
                    
                    EpisodeListView(podcast: sp)
                    
                } else {
                    
                    NoDataView(message: "Loading episodes...") {
                        _ = await Backend.shared.loadEpisodesForGUI(for: sp)
                        self.userData.selectedPodcast = sp
                    }
                }
            } else {
                Text("Please select an item")
            }
        }
        //        .onAppear() {
        //            print("on appear")
        //            Task {
        //
        //                // I used this to import the podcast
        //                try await Backend.shared.importPodcast()
        //                try await Backend.shared.importEpisode()
        //            }
        //        }
        //        .environmentObject(userData)
        
    }
    
}

struct PodcastCategoryView: View {
    let category : [Podcast.Category]
    let selectedCategory : Binding<Podcast.Category?>
    
    var body: some View {
        List(category, selection: selectedCategory) { item in
            HStack(spacing: 10) {
                item.icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                NavigationLink(
                    item.rawValue.localizedCapitalized,
                    value: item
                )
                .font(.system(.title3, design: .rounded))
            }
        }
        .navigationTitle("Podcast 🎙🎧 Categories")
    }
}

struct PodcastListView: View {
    let podcast : [Podcast]
    let selectedPodcast : Binding<Podcast?>
    
    var body: some View {
        VStack {
            List(podcast, selection: selectedPodcast) { podcast in
                NavigationLink(value: podcast) {
                    PodcastView(podcast: podcast)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct EpisodeListView: View {
    let podcast : Podcast
    
    var body: some View {
        VStack {
            List(podcast.episodes!) { episode in
                EpisodeView(podcast: podcast, episode: episode)
                    .swipeActions(edge: .trailing) {
                        Button (action: { self.deleteEpisode(episode) }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
            }.toolbar { DataStoreControlView(selectedPodcast: podcast) }
        }
    }
    
    private func deleteEpisode(_ episode : Podcast.Episode) {
        guard episode.id.count > 7 else {
            print("let's not delete built-in episodes")
            return
        }
        
        //call backend on background to delete episode and refresh UI
        Task {
            await Backend.shared.deleteEpisode(episode: episode)
        }
    }
}

struct NoDataView: View {
    let message : String
    let perform : () async -> Void
    
    var body: some View {
        CircularProgressView(strokeWidth: 20, text: message)
            .frame(width:200, height:200)
            .onAppear() {
                Task {
                    await perform()
                }
            }
    }
}

struct NavigationManagerView_Previews: PreviewProvider {
    static var previews: some View {
        
        // variable podcast is loaded from JSON, just for previews
        //        let userData = UserData()
        let userData = UserData(podcastList: podcast, selectedPodcast: podcast[0])
        //        let userData = UserData(podcastList: [], selectedPodcast: podcast[0])
        NavigationManagerView().environmentObject(userData)
    }
}
