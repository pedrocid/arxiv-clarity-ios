import Foundation
import ArxivSwift

@MainActor
public class ArxivService {
    
    public init() {}
    
    /// Fetch the latest papers from a specific category
    public func getLatest(forCategory category: String = "cs", maxResults: Int = 20) async throws -> [ArxivEntry] {
        let query = "cat:\(category)"
        return try await Arxiv.query(
            searchQuery: query,
            sortBy: .submittedDate,
            sortOrder: .descending,
            maxResults: maxResults
        )
    }
    
    /// Perform a search query with optional category filter
    public func performQuery(
        searchQuery: String,
        category: String? = nil,
        sortBy: Arxiv.SortBy = .relevance,
        sortOrder: Arxiv.SortOrder = .descending,
        maxResults: Int = 50
    ) async throws -> [ArxivEntry] {
        
        var finalQuery = searchQuery
        
        // Add category filter if specified
        if let category = category, !category.isEmpty {
            finalQuery = "cat:\(category) AND (\(searchQuery))"
        }
        
        return try await Arxiv.query(
            searchQuery: finalQuery,
            sortBy: sortBy,
            sortOrder: sortOrder,
            maxResults: maxResults
        )
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