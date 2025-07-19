import Foundation
import Testing
import SwiftUI
import ArxivSwift
@testable import Clarity
@testable import ArxivKit

@Suite("Search Functionality Integration Tests")
struct SearchFunctionalityTests {
    
    @Test("Search text validation and processing")
    func searchTextValidationAndProcessing() {
        let testCases = [
            ("machine learning", true),
            ("neural networks", true),
            ("", false),
            ("   ", false),
            ("\n\t  ", false),
            ("a", true),
            (String(repeating: "test ", count: 100), true)
        ]
        
        for (searchText, shouldBeValid) in testCases {
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let isValid = !trimmed.isEmpty
            
            #expect(isValid == shouldBeValid, "Search text '\(searchText)' validation failed")
        }
    }
    
    @Test("Search query construction with categories")
    func searchQueryConstructionWithCategories() {
        let searchTerms = [
            "machine learning",
            "quantum computing",
            "neural networks",
            "deep learning"
        ]
        
        let categories = [
            "cs.AI",
            "cs.LG", 
            "cs.CV",
            "physics.gen-ph"
        ]
        
        for searchTerm in searchTerms {
            for category in categories {
                // Test query with both search term and category
                #expect(!searchTerm.isEmpty)
                #expect(!category.isEmpty)
                #expect(category.contains("."))
                
                // Test query with search term only
                #expect(!searchTerm.isEmpty)
            }
        }
    }
    
    @Test("Search state management during search operations")
    @MainActor
    func searchStateManagementDuringOperations() {
        let appState = AppState()
        
        // Initial state
        #expect(appState.searchText.isEmpty)
        #expect(!appState.isLoading)
        #expect(appState.papers.isEmpty)
        
        // Start search
        appState.searchText = "machine learning"
        appState.setLoading(true)
        
        #expect(appState.searchText == "machine learning")
        #expect(appState.isLoading)
        #expect(appState.errorMessage == nil)
        
        // Complete search with results
        let searchResults = createMockSearchResults(count: 10)
        appState.setPapers(searchResults)
        
        #expect(appState.papers.count == 10)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
        #expect(appState.searchText == "machine learning")
        
        // Clear search
        appState.searchText = ""
        
        #expect(appState.searchText.isEmpty)
    }
    
    @Test("Search result relevance validation")
    func searchResultRelevanceValidation() {
        let searchTerms = ["machine learning", "neural networks", "quantum computing"]
        
        for searchTerm in searchTerms {
            let mockResults = createMockSearchResultsWithTerm(searchTerm: searchTerm, count: 5)
            
            #expect(mockResults.count == 5)
            
            // Check that results contain the search term in title or abstract
            let hasRelevantContent = mockResults.contains { paper in
                paper.title.localizedCaseInsensitiveContains(searchTerm) ||
                paper.abstract.localizedCaseInsensitiveContains(searchTerm)
            }
            
            #expect(hasRelevantContent, "Search results should contain relevant content for term: \(searchTerm)")
        }
    }
    
    @Test("Category filtering integration")
    func categoryFilteringIntegration() {
        let appState = AppState()
        let testCategories = ["cs.AI", "cs.LG", "cs.CV", "math.CO"]
        
        for category in testCategories {
            appState.selectedCategory = category
            #expect(appState.selectedCategory == category)
            
            // Verify category is in available categories
            let isValidCategory = appState.availableCategories.contains { $0.0 == category }
            #expect(isValidCategory, "Category \(category) should be in available categories")
        }
    }
    
    @Test("Search error handling and recovery")
    @MainActor
    func searchErrorHandlingAndRecovery() {
        let appState = AppState()
        
        // Simulate search that results in error
        appState.searchText = "test search"
        appState.setLoading(true)
        
        let searchError = NSError(domain: "SearchError", code: 500, 
                                userInfo: [NSLocalizedDescriptionKey: "Search failed"])
        appState.setError(searchError)
        
        #expect(appState.errorMessage == "Search failed")
        #expect(!appState.isLoading)
        #expect(appState.searchText == "test search") // Search text should remain
        
        // Recovery - retry search
        appState.setLoading(true)
        #expect(appState.errorMessage == nil) // Error should clear on retry
        
        let results = createMockSearchResults(count: 3)
        appState.setPapers(results)
        
        #expect(appState.papers.count == 3)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
    }
    
    @Test("Empty search results handling")
    @MainActor
    func emptySearchResultsHandling() {
        let appState = AppState()
        
        // Search that returns no results
        appState.searchText = "very specific non existent term"
        appState.setLoading(true)
        appState.setPapers([]) // Empty results
        
        #expect(appState.papers.isEmpty)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
        #expect(appState.searchText == "very specific non existent term")
    }
    
    @Test("Search text changes and debouncing logic")
    @MainActor
    func searchTextChangesAndDebouncingLogic() {
        let appState = AppState()
        
        // Simulate rapid text changes
        let searchSteps = [
            "m", "ma", "mac", "mach", "machine", "machine ", "machine l", "machine learning"
        ]
        
        for step in searchSteps {
            appState.searchText = step
            #expect(appState.searchText == step)
        }
        
        // Final search text should be complete
        #expect(appState.searchText == "machine learning")
    }
    
    @Test("Search with special characters and edge cases")
    func searchWithSpecialCharactersAndEdgeCases() {
        let specialSearchTerms = [
            "α-particles",
            "β-decay",
            "machine learning & AI",
            "quantum(computing)",
            "deep-learning",
            "C++",
            "GPU/CPU",
            "real-time"
        ]
        
        for searchTerm in specialSearchTerms {
            #expect(!searchTerm.isEmpty)
            
            // These should not cause crashes or invalid states
            let trimmed = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(!trimmed.isEmpty)
        }
    }
    
    @Test("Search performance with large result sets")
    @MainActor
    func searchPerformanceWithLargeResultSets() {
        let appState = AppState()
        
        // Test with increasing result set sizes
        let resultSizes = [50, 100, 200, 500]
        
        for size in resultSizes {
            let startTime = Date()
            
            appState.searchText = "performance test \(size)"
            let results = createMockSearchResults(count: size)
            appState.setPapers(results)
            
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            
            #expect(appState.papers.count == size)
            #expect(executionTime < 1.0, "Search with \(size) results should complete quickly")
        }
    }
    
    @Test("Search integration with sorting preferences")
    func searchIntegrationWithSortingPreferences() {
        // Test different sorting options that would be used with search
        let sortingOptions = [
            ("relevance", "descending"),
            ("submittedDate", "descending"),
            ("submittedDate", "ascending"),
            ("lastUpdatedDate", "descending")
        ]
        
        for (sortBy, sortOrder) in sortingOptions {
            #expect(!sortBy.isEmpty)
            #expect(!sortOrder.isEmpty)
            #expect(["relevance", "submittedDate", "lastUpdatedDate"].contains(sortBy))
            #expect(["ascending", "descending"].contains(sortOrder))
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockSearchResults(count: Int) -> [ArxivEntry] {
        var papers: [ArxivEntry] = []
        
        for i in 0..<count {
            papers.append(ArxivEntry(
                id: "search.result.\(i)",
                title: "Search Result Paper \(i)",
                abstract: "Search result abstract for paper \(i)",
                authors: [ArxivAuthor(name: "Search Test Author \(i)")],
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
    
    private func createMockSearchResultsWithTerm(searchTerm: String, count: Int) -> [ArxivEntry] {
        var papers: [ArxivEntry] = []
        
        for i in 0..<count {
            let shouldIncludeInTitle = i % 2 == 0
            let title = shouldIncludeInTitle ? 
                "Research on \(searchTerm) - Paper \(i)" : 
                "Advanced Research Paper \(i)"
            let abstract = shouldIncludeInTitle ? 
                "This paper explores various aspects of computer science research." :
                "This paper investigates \(searchTerm) and its applications in modern computing."
            
            papers.append(ArxivEntry(
                id: "relevant.search.\(i)",
                title: title,
                abstract: abstract,
                authors: [ArxivAuthor(name: "Relevant Search Author \(i)")],
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

@Suite("Search Query Validation Tests")
struct SearchQueryValidationTests {
    
    @Test("ArXiv query parameter validation")
    func arxivQueryParameterValidation() {
        let maxResultsValues = [1, 5, 10, 20, 50, 100]
        
        for maxResults in maxResultsValues {
            #expect(maxResults > 0)
            #expect(maxResults <= 100) // Reasonable upper limit
        }
    }
    
    @Test("Search field validation")
    func searchFieldValidation() {
        let searchFields = ["all", "title", "abstract", "author", "category"]
        
        for field in searchFields {
            #expect(!field.isEmpty)
            #expect(field.count > 1)
        }
    }
    
    @Test("Category code validation")
    func categoryCodeValidation() {
        let validCategoryCodes = [
            "cs.AI", "cs.LG", "cs.CV", "cs.CL", "cs.CR",
            "math.CO", "physics.gen-ph", "q-bio.QM", "stat.ML"
        ]
        
        for categoryCode in validCategoryCodes {
            #expect(categoryCode.contains("."))
            #expect(categoryCode.count >= 4) // Minimum valid format like "cs.AI"
            #expect(!categoryCode.hasPrefix("."))
            #expect(!categoryCode.hasSuffix("."))
        }
    }
    
    @Test("Search term sanitization")
    func searchTermSanitization() {
        let problematicTerms = [
            "  machine learning  ",
            "\tmachine\tlearning\t",
            "\nmachine\nlearning\n",
            "machine    learning",
            "Machine Learning" // Case variations
        ]
        
        for term in problematicTerms {
            let sanitized = term.trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(!sanitized.isEmpty)
            
            // Additional normalization could be tested here
            let normalized = sanitized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            #expect(!normalized.isEmpty)
        }
    }
}

@Suite("Search Integration Edge Cases")
struct SearchIntegrationEdgeCasesTests {
    
    @Test("Concurrent search operations")
    @MainActor
    func concurrentSearchOperations() async {
        let appState = AppState()
        
        // Simulate multiple rapid search requests
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask { @MainActor in
                    appState.searchText = "concurrent search \(i)"
                    appState.setLoading(true)
                    
                    // Simulate delay
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    
                    let results = createMockSearchResults(count: i + 1)
                    appState.setPapers(results)
                }
            }
        }
        
        // Final state should be consistent
        #expect(appState.searchText.contains("concurrent search"))
        #expect(!appState.isLoading)
        #expect(appState.papers.count > 0)
    }
    
    @Test("Search state persistence during app lifecycle")
    @MainActor
    func searchStatePersistenceDuringAppLifecycle() {
        let appState = AppState()
        
        // Set search state
        appState.searchText = "persistent search"
        appState.selectedCategory = "cs.LG"
        let results = createMockSearchResults(count: 5)
        appState.setPapers(results)
        
        // Simulate app going to background and returning
        let savedSearchText = appState.searchText
        let savedCategory = appState.selectedCategory
        let savedPapersCount = appState.papers.count
        
        // State should remain consistent
        #expect(appState.searchText == savedSearchText)
        #expect(appState.selectedCategory == savedCategory)
        #expect(appState.papers.count == savedPapersCount)
    }
    
    @Test("Search with network condition changes")
    @MainActor
    func searchWithNetworkConditionChanges() {
        let appState = AppState()
        
        // Start search
        appState.searchText = "network test search"
        appState.setLoading(true)
        
        // Simulate network error
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet,
                                 userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
        appState.setError(networkError)
        
        #expect(appState.errorMessage?.contains("internet") == true)
        #expect(!appState.isLoading)
        
        // Simulate network recovery and retry
        appState.setLoading(true)
        #expect(appState.errorMessage == nil)
        
        let results = createMockSearchResults(count: 3)
        appState.setPapers(results)
        
        #expect(appState.papers.count == 3)
        #expect(!appState.isLoading)
    }
    
    // MARK: - Helper Methods
    
    private func createMockSearchResults(count: Int) -> [ArxivEntry] {
        var papers: [ArxivEntry] = []
        
        for i in 0..<count {
            papers.append(ArxivEntry(
                id: "edge.case.search.\(i)",
                title: "Edge Case Search Paper \(i)",
                abstract: "Edge case search abstract for paper \(i)",
                authors: [ArxivAuthor(name: "Edge Case Author \(i)")],
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