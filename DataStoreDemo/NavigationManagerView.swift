//
//  ContentView.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 05/11/2022.
//

import SwiftUI


struct NavigationManagerView: View {
    
    private let viewLoadDelay = 1.0
    
    @State private var sideBarVisibility: NavigationSplitViewVisibility = .automatic
    @State private var selectedPodcast : Podcast? = nil
    @State private var selectedCategory : Podcast.Category? = .cloud
    
    @EnvironmentObject private var viewModel: ViewModel
    
    var body: some View {
        NavigationSplitView(columnVisibility: $sideBarVisibility,
        
        sidebar: {
            
            categoryView(for: $selectedCategory)
            
        }, content: {

            if let category = selectedCategory {
                switch(viewModel.podcastState[category]) {
                case .none, .noData:
                    
                    noDataView(with: "No podcast loaded")
//                        .delayAppearance(bySeconds: viewLoadDelay)
                        .task {
                            await viewModel.loadPodcasts(for: category)
                        }

                    
                case .loading:
                    noDataView(with: "Loading podcasts...")
//                        .delayAppearance(bySeconds: viewLoadDelay)

                case .dataAvailable(let podcasts):
                    podcastListView(for: podcasts, with: $selectedPodcast)
                    
                case .error(let error):
                    Text("There was an error: \(error.localizedDescription)")
                }
            } else {
                Text("No Category selected")
            }

        }, detail: {
            
            if let podcast = selectedPodcast {
                switch(viewModel.episodeState[podcast.id]) {
                case .none,  .noData:
                    noDataView(with: "No episode data")
//                        .delayAppearance(bySeconds: viewLoadDelay)
                        .task {
                            await viewModel.loadEpisodes(for: podcast)
                        }
                    
                case .loading:
                    noDataView(with: "Loading episodes...")
//                        .delayAppearance(bySeconds: viewLoadDelay)

                case .dataAvailable(let episodes):
                    episodeListView(with: episodes, for: selectedPodcast)
                    
                case .error(let error):
                    Text("There was an error: \(error.localizedDescription)")
                }
            } else {
                Text("no podcast selected")
            }
        })
//        .onAppear() {
//            print("on appear")
//            Task {
//                // I used this to import the podcast
//                try await Backend.shared.clearLocalData()
//                try await Backend.shared.importPodcast()
//                try await Backend.shared.importEpisode()
//            }
//        }
    }
    
    @ViewBuilder
    func categoryView(for selectedCategory: Binding<Podcast.Category?>) -> some View {
        List(self.viewModel.podcastCategories(), selection: selectedCategory) { item in
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
    
    @ViewBuilder
    func podcastListView(for podcast: [Podcast], with selectedPodcast: Binding<Podcast?>) -> some View {
        VStack {
            List(podcast, selection: selectedPodcast) { podcast in
                NavigationLink(value: podcast) {
                    PodcastView(podcast: podcast)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    func episodeListView(with episodes : [Podcast.Episode],for podcast: Podcast?) -> some View {
        VStack {
            List(episodes) { episode in
                EpisodeView(podcast: podcast, episode: episode)
                    .swipeActions(edge: .trailing) {
                        Button (action: { viewModel.deleteEpisode(episode, of: podcast) }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
            }.toolbar { DataStoreControlView(selectedPodcast: podcast) }
        }
    }
    @ViewBuilder
    func noDataView(with message: String) -> some View {
//        CircularProgressView(strokeWidth: 20, text: message)
        VStack(spacing: 50) {
            ProgressView()
            Text(message)
        }
//        .background(.red)
        .frame(width:200, height:200)
    }
}

struct NavigationManagerView_Previews: PreviewProvider {

    static var previews: some View {
                
        // variable podcast is loaded from JSON, just for previews
        NavigationManagerView().environmentObject(ViewModel.mock)
//        NavigationManagerView().noDataView(with: "Loading podcast episodes")
    }
}
