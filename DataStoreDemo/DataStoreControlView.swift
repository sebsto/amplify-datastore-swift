//
//  DataStoreControl.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 07/11/2022.
//

import SwiftUI

struct DataStoreControlView: View {
    
    @EnvironmentObject private var viewModel: MainView.ViewModel
    var selectedPodcast : Podcast?
    
    var body: some View {
        
        HStack(alignment: .center) {
            
            Spacer()
            button(text: "Add", image: "plus.circle", help: "Add an episode") {
                if let selectedPodcast {
                    viewModel.addEpisode(for: selectedPodcast)
                }
            }
            
            Spacer()
            button(text: "Reload", image: "arrow.triangle.2.circlepath.circle", help: "Reload all data") {
                viewModel.reload()
            }

            
            Spacer()
            button(text: "Empty", image: "trash", help: "Remove local data") {
                viewModel.clearLocalData()
            }
            
            Spacer()
        }
        .frame(width: nil, height: 80)
        //        .border(.red)
    }
    
    @ViewBuilder
    func button(text: String, image : String, help: String, action : @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Label(text, systemImage: image)
//                    .labelStyle(VerticalLabelStyle())
        }
        .help(help)
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
            .environmentObject(MainView.ViewModel())
    }
}
