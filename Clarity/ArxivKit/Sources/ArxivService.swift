import Foundation
import ArxivSwift

public class ArxivService {
    
    private let client: ArxivClient
    
    public init() {
        self.client = ArxivClient()
    }
    
    /// Fetch interesting and diverse papers for the home screen
    @MainActor
    public func getInterestingPapers(maxResults: Int = 20) async throws -> [ArxivEntry] {
        print("🌟 ArxivService: Fetching interesting papers")
        
        // Define interesting search terms that tend to yield curious papers
        let interestingTerms = [
            "quantum computing breakthrough",
            "artificial intelligence consciousness", 
            "neural networks creativity",
            "machine learning art",
            "robotics human interaction",
            "computer vision medical",
            "natural language understanding",
            "deep learning interpretability"
        ]
        
        // Pick a random interesting term
        let searchTerm = interestingTerms.randomElement() ?? "artificial intelligence"
        
        do {
            let query = ArxivQuery()
                .addSearch(field: .all, value: searchTerm)
                .maxResults(maxResults)
                .sort(by: .submittedDate, order: .descending)
            
            let papers = try await client.getEntries(for: query)
            print("✅ ArxivService: Successfully fetched \(papers.count) interesting papers with term: '\(searchTerm)'")
            return papers
        } catch {
            print("❌ ArxivService: Error fetching interesting papers: \(error)")
            // Fallback to latest AI papers if the search fails
            return try await getLatest(forCategory: "cs.AI", maxResults: maxResults)
        }
    }
    
    /// Fetch the latest papers from a specific category
    @MainActor
    public func getLatest(forCategory category: String = "cs.AI", maxResults: Int = 20) async throws -> [ArxivEntry] {
        print("🔍 ArxivService: Fetching latest papers for category: \(category), maxResults: \(maxResults)")
        
        do {
            // Use searchByCategory which is more reliable than getLatestEntries
            let papers = try await client.searchByCategory(
                category,
                maxResults: maxResults,
                sortBy: .submittedDate
            )
            print("✅ ArxivService: Successfully fetched \(papers.count) papers")
            return papers
        } catch {
            print("❌ ArxivService: Error fetching papers: \(error)")
            throw error
        }
    }
    
    /// Perform a search query with optional category filter
    @MainActor
    public func performQuery(
        searchQuery: String,
        category: String? = nil,
        sortBy: SortBy = .relevance,
        sortOrder: ArxivSwift.SortOrder = .descending,
        maxResults: Int = 50
    ) async throws -> [ArxivEntry] {
        
        print("🔍 ArxivService: Performing search query: '\(searchQuery)', category: \(category ?? "none"), maxResults: \(maxResults)")
        
        let query: ArxivQuery
        
        if let category = category, !category.isEmpty {
            // Create a query that combines category and search terms
            query = ArxivQuery()
                .addSearch(field: .category, value: category)
                .addSearch(field: .all, value: searchQuery)
                .maxResults(maxResults)
                .sort(by: sortBy, order: sortOrder)
        } else {
            // Search all fields
            query = ArxivQuery()
                .addSearch(field: .all, value: searchQuery)
                .maxResults(maxResults)
                .sort(by: sortBy, order: sortOrder)
        }
        
        do {
            let papers = try await client.getEntries(for: query)
            print("✅ ArxivService: Successfully found \(papers.count) papers for search")
            return papers
        } catch {
            print("❌ ArxivService: Error searching papers: \(error)")
            throw error
        }
    }
}

// MARK: - Environment Key for Dependency Injection
import SwiftUI

private struct ArxivServiceKey: EnvironmentKey {
    static let defaultValue = ArxivService()
}

public extension EnvironmentValues {
    var arxivService: ArxivService {
        get { self[ArxivServiceKey.self] }
        set { self[ArxivServiceKey.self] = newValue }
    }
} 