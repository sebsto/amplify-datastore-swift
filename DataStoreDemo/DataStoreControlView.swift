//
//  DataStoreControl.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 07/11/2022.
//

import SwiftUI

struct DataStoreControlView: View {
    
    var selectedPodcast : Podcast
    
    var body: some View {
        
        HStack(alignment: .center) {
            
            Spacer()
            Button {
                print("Add an episode")
                Task {
                    Backend.shared.userData.selectedPodcast = self.selectedPodcast
                    let _ = try await Backend.shared.mutateEpisodeList(for: self.selectedPodcast )
                }
            } label: {
                Label("Add", systemImage: "plus.circle")
//                    .labelStyle(VerticalLabelStyle())
            }
            .help("Add an episode")
            
            Spacer()
            Button {
                print("Reload all data")
                Task {
                    Backend.shared.userData.clear()
                    // the NavigationView triggers the reload
                    //try await Backend.shared.loadPodcastForGUI(for: .cloud)
                }
            } label: {
                Label("Reload", systemImage: "arrow.triangle.2.circlepath.circle")
//                    .labelStyle(VerticalLabelStyle())
            }
            .help("Reload all data")
            
            Spacer()
            Button {
                print("Remove local data")
                Task {
                    try await Backend.shared.clearLocalData()
                }
            } label: {
                Label("Empty", systemImage: "trash")
//                    .labelStyle(VerticalLabelStyle())
            }
            .help("Remove local data")
            
            Spacer()
        }
        .frame(width: nil, height: 80)
        //        .border(.red)
    }
}

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center, spacing: 5) {
            configuration.icon
            configuration.title
        }
    }
}
struct DataStoreControlView_Previews: PreviewProvider {
    
    static var previews: some View {
        DataStoreControlView(selectedPodcast: .mock)
    }
}
