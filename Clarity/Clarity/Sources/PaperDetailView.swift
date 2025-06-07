import SwiftUI
import ArxivKit
import ArxivSwift
import SafariServices

struct PaperDetailView: View {
    let paper: ArxivEntry
    @State private var showingSafari = false
    @State private var showingDownloadAlert = false
    @State private var isDownloading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(paper.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                
                // Authors
                VStack(alignment: .leading, spacing: 8) {
                    Text("Authors")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(paper.authors, id: \.name) { author in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(author.name)
                                .font(.subheadline)
                        }
                    }
                }
                
                // Publication Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Publication Info")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                        Text("Published: \(formattedDate(paper.published))")
                            .font(.subheadline)
                    }
                    
                    if paper.updated != paper.published {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                            Text("Updated: \(formattedDate(paper.updated))")
                                .font(.subheadline)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.purple)
                        Text("ArXiv ID: \(paper.id)")
                            .font(.subheadline)
                            .textSelection(.enabled)
                    }
                }
                
                // Categories
                if !paper.categories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Categories")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100))
                        ], spacing: 8) {
                            ForEach(paper.categories, id: \.term) { category in
                                Text(category.term)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                
                // Abstract
                VStack(alignment: .leading, spacing: 8) {
                    Text("Abstract")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(paper.abstract)
                        .font(.body)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Read in Browser Button
                    Button(action: {
                        showingSafari = true
                    }) {
                        HStack {
                            Image(systemName: "safari")
                            Text("Read in Browser")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // Download PDF Button
                    Button(action: {
                        downloadPDF()
                    }) {
                        HStack {
                            if isDownloading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.down.doc")
                            }
                            Text(isDownloading ? "Downloading..." : "Download PDF")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isDownloading)
                    
                    // Copy ArXiv URL Button
                    Button(action: {
                        copyArxivURL()
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy ArXiv URL")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Paper Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSafari) {
            SafariView(url: arxivURL)
        }
        .alert("Download Complete", isPresented: $showingDownloadAlert) {
            Button("OK") { }
        } message: {
            Text("The PDF has been saved to your Files app.")
        }
    }
    
    private var arxivURL: URL {
        URL(string: "https://arxiv.org/abs/\(paper.id)")!
    }
    
    private var pdfURL: URL {
        URL(string: "https://arxiv.org/pdf/\(paper.id).pdf")!
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func downloadPDF() {
        isDownloading = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: pdfURL)
                
                // Save to Documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = "\(paper.id.replacingOccurrences(of: "/", with: "_")).pdf"
                let fileURL = documentsPath.appendingPathComponent(fileName)
                
                try data.write(to: fileURL)
                
                await MainActor.run {
                    isDownloading = false
                    showingDownloadAlert = true
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    print("Error downloading PDF: \(error)")
                }
            }
        }
    }
    
    private func copyArxivURL() {
        UIPasteboard.general.string = arxivURL.absoluteString
    }
}

// Safari View for in-app browsing
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    NavigationStack {
        Text("Paper Detail View Preview")
    }
} 