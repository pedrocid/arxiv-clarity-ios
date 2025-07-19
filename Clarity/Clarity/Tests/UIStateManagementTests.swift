import Foundation
import Testing
import SwiftUI
import ArxivSwift
@testable import Clarity
@testable import ArxivKit

@Suite("UI State Management Tests")
struct UIStateManagementTests {
    
    @Test("AppState manages loading state transitions correctly")
    @MainActor
    func loadingStateTransitions() {
        let appState = AppState()
        
        // Initial state
        #expect(!appState.isLoading)
        #expect(appState.papers.isEmpty)
        #expect(appState.errorMessage == nil)
        
        // Start loading
        appState.setLoading(true)
        #expect(appState.isLoading)
        #expect(appState.errorMessage == nil) // Loading should clear errors
        
        // Finish loading with success
        let papers = createMockPapers(count: 5)
        appState.setPapers(papers)
        #expect(!appState.isLoading)
        #expect(appState.papers.count == 5)
        #expect(appState.errorMessage == nil)
    }
    
    @Test("AppState manages error state transitions correctly")
    @MainActor
    func errorStateTransitions() {
        let appState = AppState()
        let testError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // Start with error
        appState.setError(testError)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == "Network error")
        
        // Loading should clear error
        appState.setLoading(true)
        #expect(appState.isLoading)
        #expect(appState.errorMessage == nil)
        
        // Error during loading
        appState.setError(testError)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == "Network error")
        
        // Clear error manually
        appState.clearError()
        #expect(appState.errorMessage == nil)
    }
    
    @Test("AppState manages empty state correctly")
    @MainActor
    func emptyStateManagement() {
        let appState = AppState()
        
        // Initially empty
        #expect(appState.papers.isEmpty)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
        
        // Load empty results
        appState.setPapers([])
        #expect(appState.papers.isEmpty)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
        
        // Load actual papers
        let papers = createMockPapers(count: 3)
        appState.setPapers(papers)
        #expect(!appState.papers.isEmpty)
        #expect(appState.papers.count == 3)
        
        // Clear papers (return to empty)
        appState.setPapers([])
        #expect(appState.papers.isEmpty)
    }
    
    @Test("AppState search state management")
    @MainActor
    func searchStateManagement() {
        let appState = AppState()
        
        // Initial search state
        #expect(appState.searchText.isEmpty)
        #expect(appState.selectedCategory == "cs.AI")
        
        // Update search text
        appState.searchText = "machine learning"
        #expect(appState.searchText == "machine learning")
        
        // Clear search text
        appState.searchText = ""
        #expect(appState.searchText.isEmpty)
        
        // Change category
        appState.selectedCategory = "cs.LG"
        #expect(appState.selectedCategory == "cs.LG")
    }
    
    @Test("AppState handles rapid state changes without corruption")
    @MainActor
    func rapidStateChangesIntegrity() {
        let appState = AppState()
        
        // Simulate rapid UI interactions
        for i in 0..<50 {
            if i % 5 == 0 {
                appState.setLoading(true)
            } else if i % 5 == 1 {
                let papers = createMockPapers(count: i % 10)
                appState.setPapers(papers)
            } else if i % 5 == 2 {
                let error = NSError(domain: "TestError", code: i, userInfo: [NSLocalizedDescriptionKey: "Error \(i)"])
                appState.setError(error)
            } else if i % 5 == 3 {
                appState.clearError()
            } else {
                appState.searchText = "search \(i)"
            }
        }
        
        // State should be consistent at the end
        #expect(appState.searchText == "search 49")
        // Should not be in an invalid state (e.g., loading with error)
        if appState.isLoading {
            #expect(appState.errorMessage == nil)
        }
    }
    
    @Test("UI state consistency during concurrent operations")
    @MainActor
    func concurrentOperationsConsistency() async {
        let appState = AppState()
        
        // Simulate concurrent operations that might happen in the UI
        await withTaskGroup(of: Void.self) { group in
            // Task 1: Rapid loading state changes
            group.addTask { @MainActor in
                for i in 0..<20 {
                    appState.setLoading(i % 2 == 0)
                    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
                }
            }
            
            // Task 2: Search text updates
            group.addTask { @MainActor in
                for i in 0..<20 {
                    appState.searchText = "concurrent search \(i)"
                    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
                }
            }
            
            // Task 3: Paper updates
            group.addTask { @MainActor in
                for i in 0..<10 {
                    let papers = createMockPapers(count: i)
                    appState.setPapers(papers)
                    try? await Task.sleep(nanoseconds: 2_000_000) // 2ms
                }
            }
        }
        
        // Final state should be valid
        #expect(appState.searchText.hasPrefix("concurrent search"))
        #expect(appState.papers.count >= 0)
    }
    
    @Test("AppState handles state validation correctly")
    @MainActor
    func stateValidation() {
        let appState = AppState()
        
        // Valid states
        appState.setLoading(true)
        #expect(appState.isLoading && appState.errorMessage == nil)
        
        appState.setPapers(createMockPapers(count: 5))
        #expect(!appState.isLoading && appState.papers.count == 5 && appState.errorMessage == nil)
        
        let error = NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        appState.setError(error)
        #expect(!appState.isLoading && appState.errorMessage == "Not found")
        
        // Category validation
        for (categoryCode, _) in appState.availableCategories {
            appState.selectedCategory = categoryCode
            #expect(appState.selectedCategory == categoryCode)
            #expect(appState.availableCategories.contains { $0.0 == categoryCode })
        }
    }
    
    @Test("UI state handles edge cases gracefully")
    @MainActor
    func edgeCasesHandling() {
        let appState = AppState()
        
        // Empty search text scenarios
        appState.searchText = ""
        #expect(appState.searchText.isEmpty)
        
        appState.searchText = "   "
        #expect(appState.searchText == "   ")
        
        appState.searchText = "\n\t  "
        #expect(appState.searchText.contains("\n"))
        
        // Very long search text
        let longSearch = String(repeating: "very long search term ", count: 100)
        appState.searchText = longSearch
        #expect(appState.searchText.count > 1000)
        
        // Category edge cases
        appState.selectedCategory = ""
        #expect(appState.selectedCategory.isEmpty)
        
        // Large number of papers
        let manyPapers = createMockPapers(count: 1000)
        appState.setPapers(manyPapers)
        #expect(appState.papers.count == 1000)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
    }
    
    @Test("AppState memory management with large data sets")
    @MainActor
    func memoryManagementWithLargeDataSets() {
        let appState = AppState()
        
        // Test with increasingly large data sets
        for size in [10, 100, 500, 1000] {
            let papers = createMockPapers(count: size)
            appState.setPapers(papers)
            
            #expect(appState.papers.count == size)
            #expect(!appState.isLoading)
            #expect(appState.errorMessage == nil)
        }
        
        // Clear large data set
        appState.setPapers([])
        #expect(appState.papers.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPapers(count: Int) -> [ArxivEntry] {
        var papers: [ArxivEntry] = []
        
        for i in 0..<count {
            papers.append(ArxivEntry(
                id: "ui.test.\(i)",
                title: "UI Test Paper \(i)",
                abstract: "UI test abstract for paper \(i)",
                authors: [ArxivAuthor(name: "UI Test Author \(i)")],
                published: Date(),
                updated: Date(),
                primaryCategory: ArxivCategory(term: "cs.AI", scheme: nil, label: nil),
                categories: [ArxivCategory(term: "cs.AI", scheme: nil, label: nil)],
                links: [],
                comment: nil,
                journalRef: nil,
                doi: nil
            ))
        }
        
        return papers
    }
}

@Suite("UI Error State Management")
struct UIErrorStateManagementTests {
    
    @Test("Different error types are handled correctly")
    @MainActor
    func differentErrorTypesHandling() {
        let appState = AppState()
        
        let errors = [
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, 
                   userInfo: [NSLocalizedDescriptionKey: "No internet connection"]),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, 
                   userInfo: [NSLocalizedDescriptionKey: "Request timed out"]),
            NSError(domain: "ArxivError", code: 404, 
                   userInfo: [NSLocalizedDescriptionKey: "Paper not found"]),
            NSError(domain: "ParsingError", code: 500, 
                   userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        ]
        
        for error in errors {
            appState.setError(error)
            #expect(appState.errorMessage == error.localizedDescription)
            #expect(!appState.isLoading)
            
            appState.clearError()
            #expect(appState.errorMessage == nil)
        }
    }
    
    @Test("Error recovery scenarios")
    @MainActor
    func errorRecoveryScenarios() {
        let appState = AppState()
        
        // Scenario 1: Error -> Loading -> Success
        let error = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        appState.setError(error)
        #expect(appState.errorMessage == "Server error")
        
        appState.setLoading(true)
        #expect(appState.errorMessage == nil)
        #expect(appState.isLoading)
        
        let papers = createMockPapers(count: 3)
        appState.setPapers(papers)
        #expect(appState.papers.count == 3)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
        
        // Scenario 2: Success -> Error -> Clear -> Retry
        appState.setError(error)
        #expect(appState.errorMessage == "Server error")
        #expect(appState.papers.count == 3) // Papers should remain
        
        appState.clearError()
        #expect(appState.errorMessage == nil)
        
        appState.setLoading(true)
        appState.setPapers(createMockPapers(count: 5))
        #expect(appState.papers.count == 5)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPapers(count: Int) -> [ArxivEntry] {
        var papers: [ArxivEntry] = []
        
        for i in 0..<count {
            papers.append(ArxivEntry(
                id: "error.test.\(i)",
                title: "Error Test Paper \(i)",
                abstract: "Error test abstract for paper \(i)",
                authors: [ArxivAuthor(name: "Error Test Author \(i)")],
                published: Date(),
                updated: Date(),
                primaryCategory: ArxivCategory(term: "cs.AI", scheme: nil, label: nil),
                categories: [ArxivCategory(term: "cs.AI", scheme: nil, label: nil)],
                links: [],
                comment: nil,
                journalRef: nil,
                doi: nil
            ))
        }
        
        return papers
    }
}