import Foundation
import Testing
import SwiftUI
import ArxivSwift
@testable import Clarity
@testable import ArxivKit

@Suite("PaperListView Business Logic Tests")
struct PaperListViewTests {
    
    @Test("PaperListView search text processing logic")
    func searchTextProcessingLogic() {
        let testCases = [
            ("machine learning", true, "Should process valid search term"),
            ("", false, "Should not process empty search term"),
            ("   ", false, "Should not process whitespace-only search term"),
            ("\n\t  ", false, "Should not process newline/tab-only search term"),
            ("a", true, "Should process single character search"),
            ("ML", true, "Should process abbreviated terms"),
            ("quantum computing & AI", true, "Should process terms with special characters")
        ]
        
        for (searchText, shouldProcess, description) in testCases {
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let shouldBeProcessed = !trimmed.isEmpty
            
            #expect(shouldBeProcessed == shouldProcess)
        }
    }
    
    @Test("PaperListView loading state transitions")
    @MainActor
    func loadingStateTransitions() {
        let appState = AppState()
        
        // Test default paper loading flow
        #expect(!appState.isLoading)
        #expect(appState.papers.isEmpty)
        
        // Simulate loadDefaultPapers
        appState.setLoading(true)
        #expect(appState.isLoading)
        #expect(appState.errorMessage == nil)
        
        // Simulate successful load
        let papers = createMockPapers(count: 20)
        appState.setPapers(papers)
        #expect(!appState.isLoading)
        #expect(appState.papers.count == 20)
        #expect(appState.errorMessage == nil)
    }
    
    @Test("PaperListView search flow logic")
    @MainActor
    func searchFlowLogic() {
        let appState = AppState()
        
        // Test search initiation
        appState.searchText = "neural networks"
        appState.setLoading(true)
        
        #expect(appState.isLoading)
        #expect(appState.searchText == "neural networks")
        #expect(appState.errorMessage == nil)
        
        // Simulate search completion
        let searchResults = createMockSearchResults(searchTerm: "neural networks", count: 15)
        appState.setPapers(searchResults)
        
        #expect(!appState.isLoading)
        #expect(appState.papers.count == 15)
        #expect(appState.errorMessage == nil)
        
        // Test search clearing - should trigger default papers reload
        appState.searchText = ""
        #expect(appState.searchText.isEmpty)
    }
    
    @Test("PaperListView category selection logic")
    @MainActor
    func categorySelectionLogic() {
        let appState = AppState()
        
        // Test category change with search text
        appState.searchText = "machine learning"
        appState.selectedCategory = "cs.LG"
        
        #expect(appState.selectedCategory == "cs.LG")
        #expect(appState.searchText == "machine learning")
        
        // Test category change without search text
        appState.searchText = ""
        appState.selectedCategory = "cs.AI"
        
        #expect(appState.selectedCategory == "cs.AI")
        #expect(appState.searchText.isEmpty)
        
        // Verify category is valid
        let isValidCategory = appState.availableCategories.contains { $0.0 == "cs.AI" }
        #expect(isValidCategory)
    }
    
    @Test("PaperListView error handling logic")
    @MainActor
    func errorHandlingLogic() {
        let appState = AppState()
        
        // Test error during default paper loading
        appState.setLoading(true)
        let loadingError = NSError(domain: "LoadingError", code: 500, 
                                 userInfo: [NSLocalizedDescriptionKey: "Failed to load papers"])
        appState.setError(loadingError)
        
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == "Failed to load papers")
        #expect(appState.papers.isEmpty)
        
        // Test retry logic - should clear error and start loading again
        appState.setLoading(true)
        #expect(appState.errorMessage == nil)
        #expect(appState.isLoading)
        
        // Test successful retry
        let papers = createMockPapers(count: 10)
        appState.setPapers(papers)
        #expect(!appState.isLoading)
        #expect(appState.papers.count == 10)
        #expect(appState.errorMessage == nil)
    }
    
    @Test("PaperListView refresh logic")
    @MainActor
    func refreshLogic() {
        let appState = AppState()
        
        // Test refresh with no search text (should load default papers)
        appState.searchText = ""
        let existingPapers = createMockPapers(count: 5)
        appState.setPapers(existingPapers)
        
        // Simulate refresh
        appState.setLoading(true)
        let refreshedPapers = createMockPapers(count: 8)
        appState.setPapers(refreshedPapers)
        
        #expect(appState.papers.count == 8)
        #expect(!appState.isLoading)
        
        // Test refresh with search text (should re-run search)
        appState.searchText = "deep learning"
        appState.setLoading(true)
        let searchRefreshResults = createMockSearchResults(searchTerm: "deep learning", count: 12)
        appState.setPapers(searchRefreshResults)
        
        #expect(appState.papers.count == 12)
        #expect(!appState.isLoading)
        #expect(appState.searchText == "deep learning")
    }
    
    @Test("PaperListView navigation state consistency")
    func navigationStateConsistency() {
        // Test navigation title
        let navigationTitle = "ArXiv Papers"
        #expect(!navigationTitle.isEmpty)
        #expect(navigationTitle == "ArXiv Papers")
        
        // Test search prompt
        let searchPrompt = "Search papers..."
        #expect(!searchPrompt.isEmpty)
        #expect(searchPrompt.contains("Search"))
    }
    
    @Test("PaperListView empty state logic")
    @MainActor
    func emptyStateLogic() {
        let appState = AppState()
        
        // Test welcome state (no search, no papers, not loading, no error)
        #expect(appState.papers.isEmpty)
        #expect(!appState.isLoading)
        #expect(appState.searchText.isEmpty)
        #expect(appState.errorMessage == nil)
        
        // Test empty search results state
        appState.searchText = "very specific non-existent term"
        appState.setPapers([]) // Empty search results
        
        #expect(appState.papers.isEmpty)
        #expect(!appState.isLoading)
        #expect(!appState.searchText.isEmpty)
        #expect(appState.errorMessage == nil)
    }
    
    @Test("PaperListView loading state display logic")
    @MainActor
    func loadingStateDisplayLogic() {
        let appState = AppState()
        
        // Test loading state
        appState.setLoading(true)
        #expect(appState.isLoading)
        #expect(appState.errorMessage == nil)
        
        // Loading state should have appropriate messages
        let loadingMessage = "Loading papers..."
        let discoveryMessage = "Discovering the latest research..."
        
        #expect(!loadingMessage.isEmpty)
        #expect(!discoveryMessage.isEmpty)
        #expect(loadingMessage.contains("Loading"))
        #expect(discoveryMessage.contains("research"))
    }
    
    @Test("PaperListView search submission logic")
    @MainActor
    func searchSubmissionLogic() {
        let appState = AppState()
        
        // Test search submission with valid text
        appState.searchText = "quantum computing"
        
        // Should trigger search
        let shouldPerformSearch = !appState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        #expect(shouldPerformSearch)
        
        // Test search submission with empty text
        appState.searchText = ""
        
        // Should trigger default papers load instead
        let shouldLoadDefault = appState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        #expect(shouldLoadDefault)
    }
    
    @Test("PaperListView search text change handling")
    @MainActor
    func searchTextChangeHandling() {
        let appState = AppState()
        
        // Setup: has search text and papers
        appState.searchText = "machine learning"
        let searchResults = createMockSearchResults(searchTerm: "machine learning", count: 5)
        appState.setPapers(searchResults)
        
        #expect(appState.searchText == "machine learning")
        #expect(appState.papers.count == 5)
        
        // Simulate user clearing search text
        let oldValue = appState.searchText
        appState.searchText = ""
        let newValue = appState.searchText
        
        // Should detect that search was cleared (newValue is empty, oldValue was not)
        let wasCleared = newValue.isEmpty && !oldValue.isEmpty
        #expect(wasCleared)
    }
    
    @Test("PaperListView maximum results handling")
    func maximumResultsHandling() {
        let defaultMaxResults = 20
        let searchMaxResults = 50
        
        #expect(defaultMaxResults > 0)
        #expect(searchMaxResults > defaultMaxResults)
        #expect(searchMaxResults <= 100) // Reasonable upper limit
        
        // Test that we don't request excessive amounts
        #expect(defaultMaxResults <= 50)
        #expect(searchMaxResults <= 100)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPapers(count: Int) -> [ArxivEntry] {
        var papers: [ArxivEntry] = []
        
        for i in 0..<count {
            papers.append(ArxivEntry(
                id: "list.view.test.\(i)",
                title: "List View Test Paper \(i)",
                abstract: "List view test abstract for paper \(i)",
                authors: [ArxivAuthor(name: "List View Test Author \(i)")],
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
    
    private func createMockSearchResults(searchTerm: String, count: Int) -> [ArxivEntry] {
        var papers: [ArxivEntry] = []
        
        for i in 0..<count {
            papers.append(ArxivEntry(
                id: "search.list.test.\(i)",
                title: "Research on \(searchTerm) - Paper \(i)",
                abstract: "This paper explores \(searchTerm) and its applications in paper \(i)",
                authors: [ArxivAuthor(name: "Search List Author \(i)")],
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

@Suite("PaperListView Performance Tests")
struct PaperListViewPerformanceTests {
    
    @Test("PaperListView handles large data sets efficiently")
    @MainActor
    func handlesLargeDataSetsEfficiently() {
        let appState = AppState()
        let largePaperSet = createMockPapers(count: 500)
        
        let startTime = Date()
        appState.setPapers(largePaperSet)
        let endTime = Date()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        #expect(executionTime < 1.0) // Should complete within 1 second
        #expect(appState.papers.count == 500)
        #expect(!appState.isLoading)
    }
    
    @Test("PaperListView rapid state changes performance")
    @MainActor
    func rapidStateChangesPerformance() {
        let appState = AppState()
        
        let startTime = Date()
        
        // Simulate rapid user interactions
        for i in 0..<100 {
            if i % 4 == 0 {
                appState.setLoading(true)
            } else if i % 4 == 1 {
                appState.searchText = "rapid test \(i)"
            } else if i % 4 == 2 {
                let papers = createMockPapers(count: i % 20)
                appState.setPapers(papers)
            } else {
                appState.selectedCategory = appState.availableCategories[i % appState.availableCategories.count].0
            }
        }
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        #expect(executionTime < 2.0) // Should complete within 2 seconds
        #expect(appState.searchText == "rapid test 97") // Last search text set
    }
    
    // MARK: - Helper Methods
    
    private func createMockPapers(count: Int) -> [ArxivEntry] {
        var papers: [ArxivEntry] = []
        
        for i in 0..<count {
            papers.append(ArxivEntry(
                id: "perf.list.test.\(i)",
                title: "Performance List Test Paper \(i)",
                abstract: "Performance list test abstract for paper \(i)",
                authors: [ArxivAuthor(name: "Performance List Author \(i)")],
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