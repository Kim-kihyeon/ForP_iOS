//
//  ForPApp.swift
//  ForP
//
//  Created by 김견 on 4/14/26.
//

import SwiftUI

@main
struct ForPApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                HomeView()
                    .environment(appState)
            } else {
                LoginView()
                    .environment(appState)
            }
        }
    }
}
