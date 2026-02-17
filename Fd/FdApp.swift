//
//  FdApp.swift
//  Fd
//
//  Created by Садыг Садыгов on 21.12.2025.
//

import SwiftUI

@main
struct FdApp: App {
    
    @State private var targetUrlString: String?
    @State private var configState: ConfigRetrievalState = .pending
    @State private var currentViewState: ApplicationViewState = .initialScreen
    
    
    var body: some Scene {
        WindowGroup {
            
            ZStack {
                switch currentViewState {
                case .initialScreen:
                    SplashScreenView()
                       
                    
                case .primaryInterface:
                    ContentView()
                        #if os(macOS)
                        .frame(minWidth: 500, minHeight: 700)
                        #endif
                        
                    
                case .browserContent(let urlString):
                    if let validUrl = URL(string: urlString) {
                        BrowserContentView(targetUrl: validUrl.absoluteString)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .ignoresSafeArea(.all, edges: .bottom)
                    } else {
                        Text("Invalid URL")
                    }
                    
                case .failureMessage(let errorMessage):
                    VStack(spacing: 20) {
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(errorMessage)
                        Button("Retry") {
                            Task { await fetchConfigurationAndNavigate() }
                        }
                    }
                    .padding()
                }
            }
            .task {
                await fetchConfigurationAndNavigate()
            }
            .onChange(of: configState, initial: true) { oldValue, newValue in
                if case .completed = newValue, let url = targetUrlString, !url.isEmpty {
                    Task {
                        await verifyUrlAndNavigate(targetUrl: url)
                    }
                }
            }

            
//            ContentView()
//                #if os(macOS)
//                .frame(minWidth: 500, minHeight: 700)
//                #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 500, height: 750)
        #endif
    }
    
    
    private func fetchConfigurationAndNavigate() async {
        await MainActor.run { currentViewState = .initialScreen }
        
        let (url, state) = await DynamicConfigService.instance.retrieveTargetUrl()
        print("URL: \(url)")
        print("State: \(state)")
        
        await MainActor.run {
            self.targetUrlString = url
            self.configState = state
        }
        
        if url == nil || url?.isEmpty == true {
            navigateToPrimaryInterface()
        }
    }
    
    private func navigateToPrimaryInterface() {
        withAnimation {
            currentViewState = .primaryInterface
        }
    }
    
    private func verifyUrlAndNavigate(targetUrl: String) async {
        guard let url = URL(string: targetUrl) else {
            navigateToPrimaryInterface()
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"
        urlRequest.timeoutInterval = 10
        
        do {
            let (_, httpResponse) = try await URLSession.shared.data(for: urlRequest)
            
            if let response = httpResponse as? HTTPURLResponse,
               (200...299).contains(response.statusCode) {
                await MainActor.run {
                    currentViewState = .browserContent(targetUrl)
                }
            } else {
                navigateToPrimaryInterface()
            }
        } catch {
            navigateToPrimaryInterface()
        }
    }
}
