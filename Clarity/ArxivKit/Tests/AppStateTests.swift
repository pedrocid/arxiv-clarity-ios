import Foundation
import Testing
import ArxivSwift
@testable import ArxivKit

@Suite("AppState Comprehensive Tests")
struct AppStateTests {
    
    @Test("AppState initializes with correct default values")
    func appStateInitialization() {
        let appState = AppState()
        
        #expect(appState.papers.isEmpty)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
        #expect(appState.searchText.isEmpty)
        #expect(appState.selectedCategory == "cs.AI")
        #expect(!appState.availableCategories.isEmpty)
        #expect(appState.availableCategories.count == 9)
    }
    
    @Test("AppState search text management")
    func searchTextManagement() {
        let appState = AppState()
        let testSearchTerms = ["machine learning", "neural networks", "quantum computing", ""]
        
        for searchTerm in testSearchTerms {
            appState.searchText = searchTerm
            #expect(appState.searchText == searchTerm)
        }
    }
    
    @Test("AppState category selection")
    func categorySelection() {
        let appState = AppState()
        
        for (categoryCode, _) in appState.availableCategories {
            appState.selectedCategory = categoryCode
            #expect(appState.selectedCategory == categoryCode)
        }
    }
    
    @Test("AppState loading state management")
    @MainActor
    func loadingStateManagement() {
        let appState = AppState()
        
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
        
        appState.setLoading(true)
        #expect(appState.isLoading)
        #expect(appState.errorMessage == nil)
        
        appState.setLoading(false)
        #expect(!appState.isLoading)
    }
    
    @Test("AppState error handling")
    @MainActor
    func errorHandling() {
        let appState = AppState()
        let testError = NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Test error message"])
        
        appState.setError(testError)
        #expect(appState.errorMessage == "Test error message")
        #expect(!appState.isLoading)
        
        appState.clearError()
        #expect(appState.errorMessage == nil)
    }
    
    @Test("AppState papers management")
    @MainActor
    func papersManagement() {
        let appState = AppState()
        
        // Create mock papers
        let mockPapers = createMockPapers(count: 5)
        
        appState.setPapers(mockPapers)
        #expect(appState.papers.count == 5)
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
        
        // Test clearing papers
        appState.setPapers([])
        #expect(appState.papers.isEmpty)
    }
    
    @Test("AppState loading clears error")
    @MainActor
    func loadingClearsError() {
        let appState = AppState()
        let testError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Previous error"])
        
        appState.setError(testError)
        #expect(appState.errorMessage != nil)
        
        appState.setLoading(true)
        #expect(appState.errorMessage == nil)
        #expect(appState.isLoading)
    }
    
    @Test("AppState setPapers clears loading and error")
    @MainActor
    func setPapersClearsLoadingAndError() {
        let appState = AppState()
        let testError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Previous error"])
        
        appState.setLoading(true)
        appState.setError(testError)
        
        let mockPapers = createMockPapers(count: 3)
        appState.setPapers(mockPapers)
        
        #expect(!appState.isLoading)
        #expect(appState.errorMessage == nil)
        #expect(appState.papers.count == 3)
    }
    
    @Test("AppState available categories are valid")
    func availableCategoriesAreValid() {
        let appState = AppState()
        
        for (categoryCode, categoryName) in appState.availableCategories {
            #expect(!categoryCode.isEmpty)
            #expect(!categoryName.isEmpty)
            #expect(categoryCode.contains("."))
            #expect(categoryCode.count > 2)
            #expect(categoryName.count > 2)
        }
    }
    
    @Test("AppState category validation")
    func categoryValidation() {
        let appState = AppState()
        let validCategories = appState.availableCategories.map { $0.0 }
        
        #expect(validCategories.contains("cs.AI"))
        #expect(validCategories.contains("cs.LG"))
        #expect(validCategories.contains("cs.CV"))
        #expect(validCategories.contains("cs.CL"))
    }
    
    // MARK: - Helper Methods
    
    private func createMockPapers(count: Int) -> [ArxivEntry] {
        var papers: [ArxivEntry] = []
        
        for i in 0..<count {
            papers.append(ArxivEntry(
                id: "test.\(i)",
                title: "Test Paper \(i)",
                abstract: "Test abstract for paper \(i)",
                authors: [ArxivAuthor(name: "Test Author \(i)")],
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

@Suite("AppState Performance Tests")
struct AppStatePerformanceTests {
    
    @Test("AppState handles large paper sets efficiently")
    @MainActor
    func largeDataSetPerformance() {
        let appState = AppState()
        let largePaperSet = createMockPapers(count: 1000)
        
        let startTime = Date()
        appState.setPapers(largePaperSet)
        let endTime = Date()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        #expect(executionTime < 1.0) // Should complete within 1 second
        #expect(appState.papers.count == 1000)
    }
    
    @Test("AppState rapid state changes")
    @MainActor
    func rapidStateChanges() {
        let appState = AppState()
        
        // Rapidly change states to test for race conditions or performance issues
        for i in 0..<100 {
            appState.setLoading(i % 2 == 0)
            appState.searchText = "search \(i)"
            
            if i % 10 == 0 {
                let papers = createMockPapers(count: i % 50)
                appState.setPapers(papers)
            }
        }
        
        // Final state should be consistent
        #expect(appState.searchText == "search 99")
        #expect(!appState.isLoading)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPapers(count: Int) -> [ArxivEntry] {
        var papers: [ArxivEntry] = []
        
        for i in 0..<count {
            papers.append(ArxivEntry(
                id: "perf.test.\(i)",
                title: "Performance Test Paper \(i)",
                abstract: "Performance test abstract for paper \(i)",
                authors: [ArxivAuthor(name: "Perf Test Author \(i)")],
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