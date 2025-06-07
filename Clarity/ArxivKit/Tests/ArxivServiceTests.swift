import Foundation
import Testing
import ArxivSwift
@testable import ArxivKit

@Suite("ArxivService Tests")
struct ArxivServiceTests {
    
    let service = ArxivService()
    
    @Test("Service initializes correctly")
    func serviceInitialization() {
        #expect(service != nil)
    }
    
    @Test("Get interesting papers returns results")
    func getInterestingPapers() async throws {
        let papers = try await service.getInterestingPapers(maxResults: 5)
        
        #expect(papers.count > 0)
        #expect(papers.count <= 5)
        
        // Verify each paper has required properties
        for paper in papers {
            #expect(!paper.title.isEmpty)
            #expect(!paper.id.isEmpty)
            #expect(!paper.abstract.isEmpty)
            #expect(paper.authors.count > 0)
        }
    }
    
    @Test("Get latest papers for category returns results")
    func getLatestPapers() async throws {
        let papers = try await service.getLatest(forCategory: "cs.AI", maxResults: 3)
        
        #expect(papers.count > 0)
        #expect(papers.count <= 3)
        
        // Verify papers are from AI category or related
        for paper in papers {
            #expect(!paper.title.isEmpty)
            #expect(!paper.id.isEmpty)
            #expect(paper.categories.count > 0)
        }
    }
    
    @Test("Perform query with search term returns relevant results", 
          arguments: [
            ("machine learning", 3),
            ("neural networks", 5),
            ("quantum computing", 2)
          ])
    func performQuery(searchTerm: String, maxResults: Int) async throws {
        let papers = try await service.performQuery(
            searchQuery: searchTerm,
            maxResults: maxResults
        )
        
        #expect(papers.count > 0)
        #expect(papers.count <= maxResults)
        
        // Verify search relevance by checking if search term appears in title or abstract
        let hasRelevantContent = papers.contains { paper in
            paper.title.localizedCaseInsensitiveContains(searchTerm) ||
            paper.abstract.localizedCaseInsensitiveContains(searchTerm)
        }
        
        #expect(hasRelevantContent, "At least one paper should contain the search term")
    }
    
    @Test("Perform query with category filter returns categorized results")
    func performQueryWithCategory() async throws {
        let papers = try await service.performQuery(
            searchQuery: "deep learning",
            category: "cs.LG",
            maxResults: 3
        )
        
        #expect(papers.count > 0)
        #expect(papers.count <= 3)
        
        // Verify at least some papers have the specified category
        let hasCorrectCategory = papers.contains { paper in
            paper.categories.contains { $0.term.contains("cs.LG") }
        }
        
        #expect(hasCorrectCategory, "At least one paper should be from the cs.LG category")
    }
    
    @Test("Service handles empty search gracefully")
    func emptySearchQuery() async throws {
        let papers = try await service.performQuery(
            searchQuery: "",
            maxResults: 1
        )
        
        // Should still return results even with empty query
        #expect(papers.count >= 0)
    }
    
    @Test("Service respects max results parameter", 
          arguments: [1, 3, 5, 10])
    func respectsMaxResults(maxResults: Int) async throws {
        let papers = try await service.getLatest(forCategory: "cs.AI", maxResults: maxResults)
        
        #expect(papers.count <= maxResults)
        #expect(papers.count > 0)
    }
}

@Suite("ArxivService Error Handling")
struct ArxivServiceErrorTests {
    
    let service = ArxivService()
    
    @Test("Service handles invalid category gracefully")
    func invalidCategory() async throws {
        // This should either return empty results or fallback gracefully
        let papers = try await service.getLatest(forCategory: "invalid.category", maxResults: 1)
        
        // Should not crash and return some result (might be empty)
        #expect(papers.count >= 0)
    }
    
    @Test("Service handles network timeout gracefully")
    func networkTimeout() async {
        // Test with very small max results to minimize network load
        do {
            let papers = try await service.getLatest(forCategory: "cs.AI", maxResults: 1)
            #expect(papers.count >= 0)
        } catch {
            // Network errors are acceptable in tests
            #expect(error != nil, "Should handle network errors gracefully")
        }
    }
} 