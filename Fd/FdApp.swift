//
//  FdApp.swift
//  Fd
//
//  Created by Садыг Садыгов on 21.12.2025.
//

import SwiftUI

@main
struct FdApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 700)
                #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 500, height: 750)
        #endif
    }
}
