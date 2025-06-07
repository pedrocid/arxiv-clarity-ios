import SwiftUI
import ArxivKit
import ArxivSwift
import SafariServices

struct PaperDetailView: View {
    let paper: ArxivEntry
    @State private var showingSafari = false
    @State private var showingDownloadAlert = false
    @State private var downloadAlertMessage = ""
    @State private var isDownloading = false
    @State private var showingShareSheet = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
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
            }
            .padding()
        }
        .navigationTitle("Paper Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingSafari = true
                    }) {
                        Label("Read in Browser", systemImage: "safari")
                    }
                    
                    Button(action: {
                        downloadPDF()
                    }) {
                        Label(isDownloading ? "Downloading..." : "Download PDF", 
                              systemImage: isDownloading ? "arrow.down.circle" : "arrow.down.doc")
                    }
                    .disabled(isDownloading)
                    
                    Button(action: {
                        copyArxivURL()
                    }) {
                        Label("Copy ArXiv URL", systemImage: "doc.on.doc")
                    }
                    
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingSafari) {
            SafariView(url: arxivURL)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [arxivURL])
        }
        .alert("Download Complete", isPresented: $showingDownloadAlert) {
            Button("OK") { }
        } message: {
            Text(downloadAlertMessage)
        }
        .alert("Download Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
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
                    downloadAlertMessage = "The PDF has been saved to your Files app."
                    showingDownloadAlert = true
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    errorMessage = "Failed to download PDF: \(error.localizedDescription)"
                    showingErrorAlert = true
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

// Share Sheet for native iOS sharing
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    NavigationStack {
        Text("Paper Detail View Preview")
    }
} 