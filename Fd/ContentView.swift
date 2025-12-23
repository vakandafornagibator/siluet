//
//  ContentView.swift
//  Fd
//
//  Created by Садыг Садыгов on 21.12.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var currentScreen: AppScreen = .menu
    @State private var stats = StatsManager()
    @State private var settings = SettingsManager()
    
    var body: some View {
        ZStack {
            switch currentScreen {
            case .menu:
                MainMenuView(currentScreen: $currentScreen, stats: stats)
                    .transition(.opacity)
                
            case .game(let mode):
                GameView(
                    currentScreen: $currentScreen,
                    gameMode: mode,
                    settings: settings,
                    stats: stats
                )
                .transition(.move(edge: .trailing))
                
            case .settings:
                SettingsView(currentScreen: $currentScreen, settings: settings, stats: stats)
                    .transition(.move(edge: .trailing))
                
            case .stats:
                StatsView(currentScreen: $currentScreen, stats: stats)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentScreen)
    }
}

#Preview {
    ContentView()
}
