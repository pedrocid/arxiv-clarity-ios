import Foundation
import SwiftUI
import ArxivSwift

@Observable
public class AppState {
    
    // MARK: - Paper Data
    public var papers: [ArxivEntry] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    // MARK: - Search State
    public var searchText: String = ""
    public var selectedCategory: String = "cs.AI"
    
    // MARK: - Available Categories
    public let availableCategories = [
        ("cs.AI", "Artificial Intelligence"),
        ("cs.LG", "Machine Learning"),
        ("cs.CV", "Computer Vision"),
        ("cs.CL", "Computation and Language"),
        ("cs.CR", "Cryptography and Security"),
        ("physics.gen-ph", "General Physics"),
        ("math.CO", "Combinatorics"),
        ("q-bio.QM", "Quantitative Methods"),
        ("stat.ML", "Machine Learning (Statistics)")
    ]
    
    public init() {}
    
    // MARK: - Helper Methods
    @MainActor
    public func clearError() {
        errorMessage = nil
    }
    
    @MainActor
    public func setLoading(_ loading: Bool) {
        print("📱 AppState: Setting loading to \(loading)")
        isLoading = loading
        if loading {
            errorMessage = nil
        }
    }
    
    @MainActor
    public func setError(_ error: Error) {
        print("❌ AppState: Setting error: \(error.localizedDescription)")
        errorMessage = error.localizedDescription
        isLoading = false
    }
    
    @MainActor
    public func setPapers(_ newPapers: [ArxivEntry]) {
        print("📄 AppState: Setting \(newPapers.count) papers")
        papers = newPapers
        isLoading = false
        errorMessage = nil
    }
}

// MARK: - Environment Key for Dependency Injection
private struct AppStateKey: EnvironmentKey {
    static let defaultValue = AppState()
}

public extension EnvironmentValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
} 