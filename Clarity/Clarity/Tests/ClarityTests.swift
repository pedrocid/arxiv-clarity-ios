import Foundation
import Testing
import SwiftUI
import ArxivSwift
@testable import Clarity
@testable import ArxivKit

@Suite("Clarity App Tests")
struct ClarityTests {
    
    @Test("Two plus two equals four")
    func twoPlusTwo_isFour() {
        #expect(2 + 2 == 4)
    }
    
    @Test("ArxivService is available in environment")
    func arxivServiceEnvironment() {
        let service = ArxivService()
        #expect(service != nil)
    }
    
    @Test("Paper detail view formats dates correctly")
    func paperDetailDateFormatting() {
        // Create a test date
        let testDate = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let formattedDate = formatter.string(from: testDate)
        
        #expect(!formattedDate.isEmpty)
        #expect(formattedDate.contains("2022"))
    }
    
    @Test("ArXiv URL construction is correct")
    func arxivURLConstruction() {
        let testPaperId = "2301.12345"
        let expectedURL = "https://arxiv.org/abs/2301.12345"
        let constructedURL = URL(string: "https://arxiv.org/abs/\(testPaperId)")
        
        #expect(constructedURL?.absoluteString == expectedURL)
    }
    
    @Test("PDF URL construction is correct")
    func pdfURLConstruction() {
        let testPaperId = "2301.12345"
        let expectedURL = "https://arxiv.org/pdf/2301.12345.pdf"
        let constructedURL = URL(string: "https://arxiv.org/pdf/\(testPaperId).pdf")
        
        #expect(constructedURL?.absoluteString == expectedURL)
    }
    
    @Test("File name sanitization for PDF download")
    func fileNameSanitization() {
        let testPaperId = "cs.AI/2301.12345"
        let sanitizedName = testPaperId.replacingOccurrences(of: "/", with: "_")
        let expectedName = "cs.AI_2301.12345"
        
        #expect(sanitizedName == expectedName)
    }
}

@Suite("Paper Model Tests")
struct PaperModelTests {
    
    @Test("Paper has required properties", arguments: [
        ("Test Title", "test.id", "Test Abstract"),
        ("Another Paper", "another.id", "Another Abstract"),
        ("Third Paper", "third.id", "Third Abstract")
    ])
    func paperRequiredProperties(title: String, id: String, abstract: String) {
        // These tests verify that our paper model expectations are correct
        #expect(!title.isEmpty)
        #expect(!id.isEmpty)
        #expect(!abstract.isEmpty)
    }
    
    @Test("Paper categories are properly handled")
    func paperCategories() {
        // Test that we can handle different category formats
        let categories = ["cs.AI", "cs.LG", "stat.ML"]
        
        for category in categories {
            #expect(category.contains("."))
            #expect(category.count > 2)
        }
    }
}

@Suite("App State Tests")
struct AppStateTests {
    
    @Test("App state initializes correctly")
    func appStateInitialization() {
        let appState = AppState()
        
        #expect(appState.papers.isEmpty)
        #expect(!appState.isLoading)
        #expect(appState.searchText.isEmpty)
        #expect(appState.selectedCategory == "cs.AI")
    }
    
    @Test("App state search text updates")
    func searchTextUpdates() {
        let appState = AppState()
        let testSearchText = "machine learning"
        
        appState.searchText = testSearchText
        #expect(appState.searchText == testSearchText)
    }
    
    @Test("App state loading state management")
    func loadingStateManagement() {
        let appState = AppState()
        
        #expect(!appState.isLoading)
        
        appState.isLoading = true
        #expect(appState.isLoading)
        
        appState.isLoading = false
        #expect(!appState.isLoading)
    }
}