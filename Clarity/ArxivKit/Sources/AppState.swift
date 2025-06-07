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
    public var selectedCategory: String = "cs"
    
    // MARK: - Available Categories
    public let availableCategories = [
        ("cs", "Computer Science"),
        ("physics", "Physics"),
        ("math", "Mathematics"),
        ("q-bio", "Quantitative Biology"),
        ("q-fin", "Quantitative Finance"),
        ("stat", "Statistics"),
        ("eess", "Electrical Engineering"),
        ("econ", "Economics")
    ]
    
    public init() {}
    
    // MARK: - Helper Methods
    @MainActor
    public func clearError() {
        errorMessage = nil
    }
    
    @MainActor
    public func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            errorMessage = nil
        }
    }
    
    @MainActor
    public func setError(_ error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }
    
    @MainActor
    public func setPapers(_ newPapers: [ArxivEntry]) {
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