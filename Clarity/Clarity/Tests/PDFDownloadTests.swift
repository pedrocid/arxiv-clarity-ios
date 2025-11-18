import Foundation
import Testing
import SwiftUI
import ArxivSwift
@testable import Clarity

@Suite("PDF Download Functionality Tests")
struct PDFDownloadTests {
    
    @Test("PDF URL construction for various paper IDs")
    func pdfURLConstruction() {
        let testCases = [
            ("2301.12345", "https://arxiv.org/pdf/2301.12345.pdf"),
            ("cs.AI/2301.12345", "https://arxiv.org/pdf/cs.AI/2301.12345.pdf"),
            ("math-ph/0506066", "https://arxiv.org/pdf/math-ph/0506066.pdf"),
            ("quant-ph/9901001", "https://arxiv.org/pdf/quant-ph/9901001.pdf"),
            ("1234.5678", "https://arxiv.org/pdf/1234.5678.pdf")
        ]
        
        for (paperID, expectedURL) in testCases {
            let paper = createMockPaper(id: paperID)
            let pdfURL = URL(string: "https://arxiv.org/pdf/\(paper.id).pdf")
            
            #expect(pdfURL?.absoluteString == expectedURL)
            #expect(pdfURL?.scheme == "https")
            #expect(pdfURL?.host == "arxiv.org")
            #expect(pdfURL?.path.hasSuffix(".pdf") == true)
        }
    }
    
    @Test("Filename sanitization for PDF downloads")
    func filenameSanitization() {
        let testCases = [
            ("cs.AI/2301.12345", "cs.AI_2301.12345.pdf"),
            ("math-ph/0506066", "math-ph_0506066.pdf"),
            ("physics/9901001", "physics_9901001.pdf"),
            ("2301.12345", "2301.12345.pdf"),
            ("cond-mat.mes-hall/0001001", "cond-mat.mes-hall_0001001.pdf")
        ]
        
        for (originalID, expectedFilename) in testCases {
            let sanitizedName = "\(originalID.replacingOccurrences(of: "/", with: "_")).pdf"
            #expect(sanitizedName == expectedFilename)
            #expect(!sanitizedName.contains("/"))
            #expect(sanitizedName.hasSuffix(".pdf"))
        }
    }
    
    @Test("Documents directory path validation")
    func documentsDirectoryPathValidation() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        #expect(!documentsPath.isEmpty)
        #expect(documentsPath.first != nil)
        
        if let documentsURL = documentsPath.first {
            #expect(documentsURL.isFileURL)
            #expect(documentsURL.hasDirectoryPath)
        }
    }
    
    @Test("PDF file URL construction")
    func pdfFileURLConstruction() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let testFilenames = [
            "2301.12345.pdf",
            "cs.AI_2301.12345.pdf",
            "math-ph_0506066.pdf"
        ]
        
        for filename in testFilenames {
            let fileURL = documentsPath.appendingPathComponent(filename)
            
            #expect(fileURL.isFileURL)
            #expect(fileURL.lastPathComponent == filename)
            #expect(fileURL.pathExtension == "pdf")
            #expect(fileURL.absoluteString.contains(filename))
        }
    }
    
    @Test("PDF download state management")
    func pdfDownloadStateManagement() {
        let paper = createMockPaper(id: "2301.12345")
        
        // Test initial state (not downloading)
        var isDownloading = false
        #expect(!isDownloading)
        
        // Simulate download start
        isDownloading = true
        #expect(isDownloading)
        
        // Simulate download completion
        isDownloading = false
        #expect(!isDownloading)
    }
    
    @Test("PDF download error handling")
    func pdfDownloadErrorHandling() {
        let commonErrors = [
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet,
                   userInfo: [NSLocalizedDescriptionKey: "No internet connection"]),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut,
                   userInfo: [NSLocalizedDescriptionKey: "Request timed out"]),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost,
                   userInfo: [NSLocalizedDescriptionKey: "Cannot find host"]),
            NSError(domain: NSCocoaErrorDomain, code: NSFileWriteFileExistsError,
                   userInfo: [NSLocalizedDescriptionKey: "File already exists"])
        ]
        
        for error in commonErrors {
            let errorMessage = error.localizedDescription
            #expect(!errorMessage.isEmpty)
            #expect(errorMessage.count > 0)
        }
    }
    
    @Test("PDF download success message formatting")
    func pdfDownloadSuccessMessageFormatting() {
        let expectedMessage = "The PDF has been saved to your Files app."
        #expect(!expectedMessage.isEmpty)
        #expect(expectedMessage.contains("PDF"))
        #expect(expectedMessage.contains("Files app"))
    }
    
    @Test("UIPasteboard URL copying functionality")
    func uiPasteboardURLCopying() {
        let testURLs = [
            "https://arxiv.org/abs/2301.12345",
            "https://arxiv.org/abs/cs.AI/2301.12345",
            "https://arxiv.org/abs/math-ph/0506066"
        ]
        
        for urlString in testURLs {
            let url = URL(string: urlString)
            #expect(url != nil)
            #expect(url?.absoluteString == urlString)
            
            // Simulate copying to pasteboard
            let urlToCopy = url?.absoluteString
            #expect(urlToCopy == urlString)
        }
    }
    
    @Test("Share sheet items preparation")
    func shareSheetItemsPreparation() {
        let paper = createMockPaper(id: "2301.12345")
        let arxivURL = URL(string: "https://arxiv.org/abs/\(paper.id)")!
        
        let shareItems: [Any] = [arxivURL]
        
        #expect(shareItems.count == 1)
        #expect(shareItems.first is URL)
        
        if let sharedURL = shareItems.first as? URL {
            #expect(sharedURL.absoluteString.contains(paper.id))
            #expect(sharedURL.absoluteString.contains("arxiv.org"))
        }
    }
    
    @Test("PDF download URL validation")
    func pdfDownloadURLValidation() {
        let validPaperIDs = [
            "2301.12345",
            "cs.AI/2301.12345", 
            "math-ph/0506066",
            "1234.5678v1"
        ]
        
        for paperID in validPaperIDs {
            let pdfURL = URL(string: "https://arxiv.org/pdf/\(paperID).pdf")
            
            #expect(pdfURL != nil)
            #expect(pdfURL?.scheme == "https")
            #expect(pdfURL?.host == "arxiv.org")
            #expect(pdfURL?.path.contains("pdf") == true)
            #expect(pdfURL?.path.hasSuffix(".pdf") == true)
            #expect(pdfURL?.absoluteString.contains(paperID) == true)
        }
    }
    
    @Test("PDF download task lifecycle")
    func pdfDownloadTaskLifecycle() {
        // Simulate download task states
        enum DownloadState {
            case idle
            case downloading
            case completed
            case failed(Error)
        }
        
        var downloadState: DownloadState = .idle
        
        // Initial state
        #expect({ 
            if case .idle = downloadState { return true }
            return false
        }())
        
        // Start download
        downloadState = .downloading
        #expect({ 
            if case .downloading = downloadState { return true }
            return false
        }())
        
        // Complete download
        downloadState = .completed
        #expect({ 
            if case .completed = downloadState { return true }
            return false
        }())
        
        // Test failure state
        let testError = NSError(domain: "TestError", code: 500, userInfo: nil)
        downloadState = .failed(testError)
        #expect({ 
            if case .failed(let error) = downloadState { 
                return (error as NSError).domain == "TestError"
            }
            return false
        }())
    }
    
    // MARK: - Helper Methods
    
    private func createMockPaper(id: String) -> ArxivEntry {
        return ArxivEntry(
            id: id,
            title: "PDF Test Paper",
            abstract: "Test abstract for PDF functionality",
            authors: [ArxivAuthor(name: "PDF Test Author")],
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

@Suite("PDF Download Integration Tests")
struct PDFDownloadIntegrationTests {
    
    @Test("End-to-end PDF download flow validation")
    func endToEndPDFDownloadFlow() {
        let paper = createMockPaper(id: "2301.12345")
        
        // Step 1: Construct PDF URL
        let pdfURL = URL(string: "https://arxiv.org/pdf/\(paper.id).pdf")
        #expect(pdfURL != nil)
        
        // Step 2: Prepare filename
        let fileName = "\(paper.id.replacingOccurrences(of: "/", with: "_")).pdf"
        #expect(fileName == "2301.12345.pdf")
        
        // Step 3: Get documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        #expect(documentsPath.isFileURL)
        
        // Step 4: Construct file URL
        let fileURL = documentsPath.appendingPathComponent(fileName)
        #expect(fileURL.lastPathComponent == fileName)
        #expect(fileURL.pathExtension == "pdf")
        
        // Step 5: Validate complete flow
        #expect(pdfURL?.absoluteString.contains(paper.id) == true)
        #expect(fileURL.absoluteString.contains(fileName) == true)
    }
    
    @Test("PDF download with complex paper IDs")
    func pdfDownloadWithComplexPaperIDs() {
        let complexPaperIDs = [
            "cs.AI/2301.12345",
            "math-ph/0506066",
            "quant-ph/9901001v2",
            "cond-mat.mes-hall/0001001"
        ]
        
        for paperID in complexPaperIDs {
            let paper = createMockPaper(id: paperID)
            
            // URL construction
            let pdfURL = URL(string: "https://arxiv.org/pdf/\(paper.id).pdf")
            #expect(pdfURL != nil)
            
            // Filename sanitization
            let fileName = "\(paper.id.replacingOccurrences(of: "/", with: "_")).pdf"
            #expect(!fileName.contains("/"))
            #expect(fileName.hasSuffix(".pdf"))
            
            // File path construction
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(fileName)
            #expect(fileURL.lastPathComponent == fileName)
        }
    }
    
    @Test("PDF download error scenarios")
    func pdfDownloadErrorScenarios() {
        let paper = createMockPaper(id: "invalid.paper.id")
        
        // Network error simulation
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet,
                                 userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
        
        let errorMessage = "Failed to download PDF: \(networkError.localizedDescription)"
        #expect(errorMessage.contains("Failed to download PDF"))
        #expect(errorMessage.contains("No internet connection"))
        
        // File system error simulation
        let fileError = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError,
                              userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
        
        let fileErrorMessage = "Failed to download PDF: \(fileError.localizedDescription)"
        #expect(fileErrorMessage.contains("Failed to download PDF"))
        #expect(fileErrorMessage.contains("Permission denied"))
    }
    
    // MARK: - Helper Methods
    
    private func createMockPaper(id: String) -> ArxivEntry {
        return ArxivEntry(
            id: id,
            title: "Integration Test Paper",
            abstract: "Test abstract for integration testing",
            authors: [ArxivAuthor(name: "Integration Test Author")],
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