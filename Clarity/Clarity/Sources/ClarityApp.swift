import SwiftUI
import ArxivKit

@main
struct ClarityApp: App {
    
    @State private var appState = AppState()
    @State private var arxivService = ArxivService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(\.arxivService, arxivService)
        }
    }
}
