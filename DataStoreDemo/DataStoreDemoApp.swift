//
//  DataStoreDemoApp.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 05/11/2022.
//

import SwiftUI

@main
struct DataStoreDemoApp: App {

    var body: some Scene {
        WindowGroup {
            MainView().environmentObject(MainView.ViewModel())
        }
    }
}
