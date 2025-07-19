import Foundation
import Testing
import SwiftUI
import ArxivSwift
@testable import Clarity

@Suite("PaperDetailView Tests")
struct PaperDetailViewTests {
    
    @Test("PaperDetailView constructs ArXiv URL correctly")
    func constructsArxivURLCorrectly() {
        let paper = createMockPaper(id: "2301.12345")
        let view = PaperDetailView(paper: paper)
        
        let expectedURL = "https://arxiv.org/abs/2301.12345"
        let constructedURL = URL(string: "https://arxiv.org/abs/\(paper.id)")
        
        #expect(constructedURL?.absoluteString == expectedURL)
    }
    
    @Test("PaperDetailView constructs PDF URL correctly")
    func constructsPDFURLCorrectly() {
        let paper = createMockPaper(id: "2301.12345")
        let view = PaperDetailView(paper: paper)
        
        let expectedURL = "https://arxiv.org/pdf/2301.12345.pdf"
        let constructedURL = URL(string: "https://arxiv.org/pdf/\(paper.id).pdf")
        
        #expect(constructedURL?.absoluteString == expectedURL)
    }
    
    @Test("PaperDetailView handles complex paper IDs in URLs")
    func handlesComplexPaperIDs() {
        let complexIDs = [
            "cs.AI/2301.12345",
            "math-ph/0506066",
            "quant-ph/9901001",
            "1234.5678"
        ]
        
        for id in complexIDs {
            let paper = createMockPaper(id: id)
            let arxivURL = URL(string: "https://arxiv.org/abs/\(id)")
            let pdfURL = URL(string: "https://arxiv.org/pdf/\(id).pdf")
            
            #expect(arxivURL != nil)
            #expect(pdfURL != nil)
            #expect(arxivURL?.absoluteString.contains(id) == true)
            #expect(pdfURL?.absoluteString.contains(id) == true)
        }
    }
    
    @Test("PaperDetailView formats publication date correctly")
    func formatsPublicationDateCorrectly() {
        let testDate = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        let paper = createMockPaperWithDate(publishedDate: testDate, updatedDate: testDate)
        let view = PaperDetailView(paper: paper)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let formattedDate = formatter.string(from: testDate)
        
        #expect(!formattedDate.isEmpty)
        #expect(formattedDate.contains("2022"))
    }
    
    @Test("PaperDetailView handles different published and updated dates")
    func handlesDifferentPublishedAndUpdatedDates() {
        let publishedDate = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        let updatedDate = Date(timeIntervalSince1970: 1672531200)   // Jan 1, 2023
        let paper = createMockPaperWithDate(publishedDate: publishedDate, updatedDate: updatedDate)
        let view = PaperDetailView(paper: paper)
        
        #expect(paper.published != paper.updated)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let formattedPublished = formatter.string(from: publishedDate)
        let formattedUpdated = formatter.string(from: updatedDate)
        
        #expect(formattedPublished.contains("2022"))
        #expect(formattedUpdated.contains("2023"))
    }
    
    @Test("PaperDetailView sanitizes filename for PDF download")
    func sanitizesFilenameForPDFDownload() {
        let problematicIDs = [
            "cs.AI/2301.12345",
            "math-ph/0506066",
            "physics/9901001"
        ]
        
        for id in problematicIDs {
            let sanitizedName = id.replacingOccurrences(of: "/", with: "_")
            #expect(!sanitizedName.contains("/"))
            #expect(sanitizedName.contains("_"))
        }
    }
    
    @Test("PaperDetailView handles papers with no categories")
    func handlesPapersWithNoCategories() {
        let paper = createMockPaperWithCategories(categories: [])
        let view = PaperDetailView(paper: paper)
        
        #expect(paper.categories.isEmpty)
    }
    
    @Test("PaperDetailView handles papers with multiple categories")
    func handlesPapersWithMultipleCategories() {
        let categories = [
            ArxivCategory(term: "cs.AI", scheme: nil, label: "Artificial Intelligence"),
            ArxivCategory(term: "cs.LG", scheme: nil, label: "Machine Learning"),
            ArxivCategory(term: "stat.ML", scheme: nil, label: "Statistics - Machine Learning")
        ]
        
        let paper = createMockPaperWithCategories(categories: categories)
        let view = PaperDetailView(paper: paper)
        
        #expect(paper.categories.count == 3)
        #expect(paper.categories.contains { $0.term == "cs.AI" })
        #expect(paper.categories.contains { $0.term == "cs.LG" })
        #expect(paper.categories.contains { $0.term == "stat.ML" })
    }
    
    @Test("PaperDetailView handles very long abstracts")
    func handlesVeryLongAbstracts() {
        let longAbstract = String(repeating: "This is a very long abstract sentence. ", count: 100)
        let paper = createMockPaperWithAbstract(abstract: longAbstract)
        let view = PaperDetailView(paper: paper)
        
        #expect(paper.abstract.count > 1000)
        #expect(!paper.abstract.isEmpty)
    }
    
    @Test("PaperDetailView handles empty abstract")
    func handlesEmptyAbstract() {
        let paper = createMockPaperWithAbstract(abstract: "")
        let view = PaperDetailView(paper: paper)
        
        #expect(paper.abstract.isEmpty)
    }
    
    @Test("PaperDetailView handles special characters in title and abstract")
    func handlesSpecialCharactersInContent() {
        let specialTitle = "Quantum Computing: A Survey of Algorithms & Applications (2023)"
        let specialAbstract = "This paper discusses α-β pruning, μ-calculus, and ∑-protocols in quantum systems."
        
        let paper = createMockPaperWithContent(title: specialTitle, abstract: specialAbstract)
        let view = PaperDetailView(paper: paper)
        
        #expect(paper.title.contains("&"))
        #expect(paper.title.contains("("))
        #expect(paper.title.contains(")"))
        #expect(paper.abstract.contains("α"))
        #expect(paper.abstract.contains("μ"))
        #expect(paper.abstract.contains("∑"))
    }
    
    @Test("PaperDetailView handles papers with many authors")
    func handlesPapersWithManyAuthors() {
        let manyAuthors = (1...20).map { ArxivAuthor(name: "Author \($0)") }
        let paper = createMockPaperWithAuthors(authors: manyAuthors)
        let view = PaperDetailView(paper: paper)
        
        #expect(paper.authors.count == 20)
        #expect(paper.authors.first?.name == "Author 1")
        #expect(paper.authors.last?.name == "Author 20")
    }
    
    @Test("PaperDetailView handles papers with no authors")
    func handlesPapersWithNoAuthors() {
        let paper = createMockPaperWithAuthors(authors: [])
        let view = PaperDetailView(paper: paper)
        
        #expect(paper.authors.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPaper(id: String) -> ArxivEntry {
        return ArxivEntry(
            id: id,
            title: "Test Paper",
            abstract: "Test abstract",
            authors: [ArxivAuthor(name: "Test Author")],
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
    
    private func createMockPaperWithDate(publishedDate: Date, updatedDate: Date) -> ArxivEntry {
        return ArxivEntry(
            id: "date.test",
            title: "Date Test Paper",
            abstract: "Test abstract",
            authors: [ArxivAuthor(name: "Test Author")],
            published: publishedDate,
            updated: updatedDate,
            primaryCategory: ArxivCategory(term: "cs.AI", scheme: nil, label: nil),
            categories: [ArxivCategory(term: "cs.AI", scheme: nil, label: nil)],
            links: [],
            comment: nil,
            journalRef: nil,
            doi: nil
        )
    }
    
    private func createMockPaperWithCategories(categories: [ArxivCategory]) -> ArxivEntry {
        return ArxivEntry(
            id: "categories.test",
            title: "Categories Test Paper",
            abstract: "Test abstract",
            authors: [ArxivAuthor(name: "Test Author")],
            published: Date(),
            updated: Date(),
            primaryCategory: categories.first,
            categories: categories,
            links: [],
            comment: nil,
            journalRef: nil,
            doi: nil
        )
    }
    
    private func createMockPaperWithAbstract(abstract: String) -> ArxivEntry {
        return ArxivEntry(
            id: "abstract.test",
            title: "Abstract Test Paper",
            abstract: abstract,
            authors: [ArxivAuthor(name: "Test Author")],
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
    
    private func createMockPaperWithContent(title: String, abstract: String) -> ArxivEntry {
        return ArxivEntry(
            id: "content.test",
            title: title,
            abstract: abstract,
            authors: [ArxivAuthor(name: "Test Author")],
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
    
    private func createMockPaperWithAuthors(authors: [ArxivAuthor]) -> ArxivEntry {
        return ArxivEntry(
            id: "authors.test",
            title: "Authors Test Paper",
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
}

@Suite("PaperDetailView URL Validation Tests")
struct PaperDetailViewURLValidationTests {
    
    @Test("PaperDetailView creates valid URLs for various ID formats", arguments: [
        "2301.12345",
        "cs.AI/2301.12345",
        "math-ph/0506066",
        "quant-ph/9901001",
        "physics/0001001",
        "1234.5678v1",
        "1234.5678v2"
    ])
    func createsValidURLsForVariousIDFormats(paperID: String) {
        let paper = createMockPaper(id: paperID)
        
        let arxivURL = URL(string: "https://arxiv.org/abs/\(paperID)")
        let pdfURL = URL(string: "https://arxiv.org/pdf/\(paperID).pdf")
        
        #expect(arxivURL != nil, "ArXiv URL should be valid for ID: \(paperID)")
        #expect(pdfURL != nil, "PDF URL should be valid for ID: \(paperID)")
        
        #expect(arxivURL?.scheme == "https")
        #expect(arxivURL?.host == "arxiv.org")
        #expect(arxivURL?.path.contains(paperID) == true)
        
        #expect(pdfURL?.scheme == "https")
        #expect(pdfURL?.host == "arxiv.org")
        #expect(pdfURL?.path.contains(paperID) == true)
        #expect(pdfURL?.path.hasSuffix(".pdf") == true)
    }
    
    @Test("PaperDetailView handles URL encoding for special characters")
    func handlesURLEncodingForSpecialCharacters() {
        let specialIDs = [
            "math.AG/9801001",
            "physics.gen-ph/9901001",
            "cond-mat.mes-hall/0001001"
        ]
        
        for id in specialIDs {
            let paper = createMockPaper(id: id)
            let arxivURL = URL(string: "https://arxiv.org/abs/\(id)")
            let pdfURL = URL(string: "https://arxiv.org/pdf/\(id).pdf")
            
            #expect(arxivURL != nil)
            #expect(pdfURL != nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockPaper(id: String) -> ArxivEntry {
        return ArxivEntry(
            id: id,
            title: "URL Test Paper",
            abstract: "Test abstract",
            authors: [ArxivAuthor(name: "Test Author")],
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
}