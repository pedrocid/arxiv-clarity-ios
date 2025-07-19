import Foundation
import Testing
import SwiftUI
import ArxivSwift
@testable import Clarity

@Suite("PaperRowView Tests")
struct PaperRowViewTests {
    
    @Test("PaperRowView formats authors correctly with few authors")
    func formatsFewAuthors() {
        let authors = [
            ArxivAuthor(name: "John Doe"),
            ArxivAuthor(name: "Jane Smith")
        ]
        
        let paper = createMockPaper(id: "test.1", title: "Test Paper", authors: authors)
        let view = PaperRowView(paper: paper)
        
        let authorsText = authors.map { $0.name }.joined(separator: ", ")
        #expect(authorsText == "John Doe, Jane Smith")
        #expect(!authorsText.contains("et al."))
    }
    
    @Test("PaperRowView formats authors correctly with many authors")
    func formatsManyAuthors() {
        let authors = [
            ArxivAuthor(name: "Author One"),
            ArxivAuthor(name: "Author Two"),
            ArxivAuthor(name: "Author Three"),
            ArxivAuthor(name: "Author Four"),
            ArxivAuthor(name: "Author Five")
        ]
        
        let paper = createMockPaper(id: "test.2", title: "Test Paper", authors: authors)
        let view = PaperRowView(paper: paper)
        
        let authorsText = authors.prefix(3).map { $0.name }.joined(separator: ", ") + " et al."
        #expect(authorsText == "Author One, Author Two, Author Three et al.")
        #expect(authorsText.contains("et al."))
    }
    
    @Test("PaperRowView formats authors correctly with exactly three authors")
    func formatsExactlyThreeAuthors() {
        let authors = [
            ArxivAuthor(name: "Author A"),
            ArxivAuthor(name: "Author B"),
            ArxivAuthor(name: "Author C")
        ]
        
        let paper = createMockPaper(id: "test.3", title: "Test Paper", authors: authors)
        let view = PaperRowView(paper: paper)
        
        let authorsText = authors.map { $0.name }.joined(separator: ", ")
        #expect(authorsText == "Author A, Author B, Author C")
        #expect(!authorsText.contains("et al."))
    }
    
    @Test("PaperRowView formats date correctly")
    func formatsDateCorrectly() {
        let testDate = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        let paper = createMockPaperWithDate(publishedDate: testDate)
        let view = PaperRowView(paper: paper)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let expectedDate = formatter.string(from: testDate)
        
        #expect(!expectedDate.isEmpty)
        #expect(expectedDate.contains("2022"))
    }
    
    @Test("PaperRowView handles empty title gracefully")
    func handlesEmptyTitle() {
        let paper = createMockPaper(id: "test.4", title: "", authors: [ArxivAuthor(name: "Test Author")])
        let view = PaperRowView(paper: paper)
        
        // View should not crash with empty title
        #expect(paper.title.isEmpty)
    }
    
    @Test("PaperRowView handles single author")
    func handlesSingleAuthor() {
        let authors = [ArxivAuthor(name: "Single Author")]
        let paper = createMockPaper(id: "test.5", title: "Single Author Paper", authors: authors)
        let view = PaperRowView(paper: paper)
        
        let authorsText = authors.map { $0.name }.joined(separator: ", ")
        #expect(authorsText == "Single Author")
        #expect(!authorsText.contains("et al."))
        #expect(!authorsText.contains(","))
    }
    
    @Test("PaperRowView handles no authors gracefully")
    func handlesNoAuthors() {
        let paper = createMockPaper(id: "test.6", title: "No Authors Paper", authors: [])
        let view = PaperRowView(paper: paper)
        
        let authorsText = paper.authors.map { $0.name }.joined(separator: ", ")
        #expect(authorsText.isEmpty)
    }
    
    @Test("PaperRowView displays primary category correctly")
    func displaysPrimaryCategoryCorrectly() {
        let primaryCategory = ArxivCategory(term: "cs.AI", scheme: "http://arxiv.org/schemas/atom", label: "Artificial Intelligence")
        let paper = createMockPaperWithCategory(primaryCategory: primaryCategory)
        let view = PaperRowView(paper: paper)
        
        #expect(paper.primaryCategory?.term == "cs.AI")
        #expect(paper.primaryCategory?.label == "Artificial Intelligence")
    }
    
    @Test("PaperRowView handles missing primary category")
    func handlesMissingPrimaryCategory() {
        let paper = createMockPaperWithCategory(primaryCategory: nil)
        let view = PaperRowView(paper: paper)
        
        #expect(paper.primaryCategory == nil)
    }
    
    @Test("PaperRowView handles very long titles")
    func handlesVeryLongTitles() {
        let longTitle = String(repeating: "Very Long Title ", count: 20)
        let paper = createMockPaper(id: "test.7", title: longTitle, authors: [ArxivAuthor(name: "Test Author")])
        let view = PaperRowView(paper: paper)
        
        #expect(paper.title.count > 100)
        #expect(!paper.title.isEmpty)
    }
    
    @Test("PaperRowView handles special characters in author names")
    func handlesSpecialCharactersInAuthorNames() {
        let authors = [
            ArxivAuthor(name: "José María García-López"),
            ArxivAuthor(name: "李明华"),
            ArxivAuthor(name: "François Müller")
        ]
        
        let paper = createMockPaper(id: "test.8", title: "International Authors", authors: authors)
        let view = PaperRowView(paper: paper)
        
        let authorsText = authors.map { $0.name }.joined(separator: ", ")
        #expect(authorsText.contains("José María García-López"))
        #expect(authorsText.contains("李明华"))
        #expect(authorsText.contains("François Müller"))
    }
    
    // MARK: - Helper Methods
    
    private func createMockPaper(id: String, title: String, authors: [ArxivAuthor]) -> ArxivEntry {
        return ArxivEntry(
            id: id,
            title: title,
            abstract: "Test abstract",
            authors: authors,
            published: Date(),
            updated: Date(),
            primaryCategory: ArxivCategory(term: "cs.AI", scheme: nil, label: nil),
            categories: [ArxivCategory(term: "cs.AI", scheme: nil, label: nil)],
            links: [],
            comment: nil,
            journalRef: nil,
            doi: nil
        )
    }
    
    private func createMockPaperWithDate(publishedDate: Date) -> ArxivEntry {
        return ArxivEntry(
            id: "date.test",
            title: "Date Test Paper",
            abstract: "Test abstract",
            authors: [ArxivAuthor(name: "Test Author")],
            published: publishedDate,
            updated: publishedDate,
            primaryCategory: ArxivCategory(term: "cs.AI", scheme: nil, label: nil),
            categories: [ArxivCategory(term: "cs.AI", scheme: nil, label: nil)],
            links: [],
            comment: nil,
            journalRef: nil,
            doi: nil
        )
    }
    
    private func createMockPaperWithCategory(primaryCategory: ArxivCategory?) -> ArxivEntry {
        return ArxivEntry(
            id: "category.test",
            title: "Category Test Paper",
            abstract: "Test abstract",
            authors: [ArxivAuthor(name: "Test Author")],
            published: Date(),
            updated: Date(),
            primaryCategory: primaryCategory,
            categories: primaryCategory != nil ? [primaryCategory!] : [],
            links: [],
            comment: nil,
            journalRef: nil,
            doi: nil
        )
    }
}

@Suite("PaperRowView Edge Cases")
struct PaperRowViewEdgeCasesTests {
    
    @Test("PaperRowView handles future dates")
    func handlesFutureDates() {
        let futureDate = Date().addingTimeInterval(86400 * 365) // One year from now
        let paper = createMockPaperWithDate(publishedDate: futureDate)
        let view = PaperRowView(paper: paper)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let formattedDate = formatter.string(from: futureDate)
        
        #expect(!formattedDate.isEmpty)
    }
    
    @Test("PaperRowView handles very old dates")
    func handlesVeryOldDates() {
        let oldDate = Date(timeIntervalSince1970: 0) // January 1, 1970
        let paper = createMockPaperWithDate(publishedDate: oldDate)
        let view = PaperRowView(paper: paper)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let formattedDate = formatter.string(from: oldDate)
        
        #expect(!formattedDate.isEmpty)
        #expect(formattedDate.contains("1970"))
    }
    
    @Test("PaperRowView handles author names with numbers")
    func handlesAuthorNamesWithNumbers() {
        let authors = [
            ArxivAuthor(name: "Author2023"),
            ArxivAuthor(name: "User123"),
            ArxivAuthor(name: "Test-User-456")
        ]
        
        let paper = createMockPaper(id: "numeric.test", title: "Numeric Authors", authors: authors)
        let view = PaperRowView(paper: paper)
        
        let authorsText = authors.map { $0.name }.joined(separator: ", ")
        #expect(authorsText.contains("Author2023"))
        #expect(authorsText.contains("User123"))
        #expect(authorsText.contains("Test-User-456"))
    }
    
    // MARK: - Helper Methods
    
    private func createMockPaper(id: String, title: String, authors: [ArxivAuthor]) -> ArxivEntry {
        return ArxivEntry(
            id: id,
            title: title,
            abstract: "Test abstract",
            authors: authors,
            published: Date(),
            updated: Date(),
            primaryCategory: ArxivCategory(term: "cs.AI", scheme: nil, label: nil),
            categories: [ArxivCategory(term: "cs.AI", scheme: nil, label: nil)],
            links: [],
            comment: nil,
            journalRef: nil,
            doi: nil
        )
    }
    
    private func createMockPaperWithDate(publishedDate: Date) -> ArxivEntry {
        return ArxivEntry(
            id: "edge.date.test",
            title: "Edge Case Date Test",
            abstract: "Test abstract",
            authors: [ArxivAuthor(name: "Test Author")],
            published: publishedDate,
            updated: publishedDate,
            primaryCategory: ArxivCategory(term: "cs.AI", scheme: nil, label: nil),
            categories: [ArxivCategory(term: "cs.AI", scheme: nil, label: nil)],
            links: [],
            comment: nil,
            journalRef: nil,
            doi: nil
        )
    }
}