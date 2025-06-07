import Foundation
import ArxivSwift

public class ArxivService {
    
    private let client: ArxivClient
    
    public init() {
        self.client = ArxivClient()
    }
    
    /// Fetch the latest papers from a specific category
    @MainActor
    public func getLatest(forCategory category: String = "cs", maxResults: Int = 20) async throws -> [ArxivEntry] {
        return try await client.getLatestEntries(maxResults: maxResults, category: category)
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
        
        return try await client.getEntries(for: query)
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