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
            VStack(alignment: .leading, spacing: 24) {
                // Title Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(paper.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Authors Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)
                                .accessibilityHidden(true)
                            Text("Authors")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .accessibilityElement(children: .combine)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(paper.authors, id: \.name) { author in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 6, height: 6)
                                        .accessibilityHidden(true)
                                    Text(author.name)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(CustomGroupBoxStyle())
                .padding(.horizontal, 20)
                
                // Publication Info Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title3)
                                .accessibilityHidden(true)
                            Text("Publication Details")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .accessibilityElement(children: .combine)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            InfoRow(icon: "calendar", color: .green, label: "Published", value: formattedDate(paper.published))
                            
                            if paper.updated != paper.published {
                                InfoRow(icon: "arrow.clockwise", color: .orange, label: "Updated", value: formattedDate(paper.updated))
                            }
                            
                            InfoRow(icon: "number", color: .purple, label: "ArXiv ID", value: paper.id, isSelectable: true)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(CustomGroupBoxStyle())
                .padding(.horizontal, 20)
                
                // Categories Section
                if !paper.categories.isEmpty {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title3)
                                    .accessibilityHidden(true)
                                Text("Categories")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            .accessibilityElement(children: .combine)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 120))
                            ], spacing: 8) {
                                ForEach(paper.categories, id: \.term) { category in
                                    Text(category.term)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .foregroundColor(.blue)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .groupBoxStyle(CustomGroupBoxStyle())
                    .padding(.horizontal, 20)
                }
                
                // Abstract Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.purple)
                                .font(.title3)
                                .accessibilityHidden(true)
                            Text("Abstract")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .accessibilityElement(children: .combine)
                        
                        Text(paper.abstract)
                            .font(.body)
                            .lineSpacing(6)
                            .textSelection(.enabled)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(CustomGroupBoxStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
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

// Custom GroupBox Style
struct CustomGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            configuration.content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// Info Row Component
struct InfoRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let isSelectable: Bool
    
    init(icon: String, color: Color, label: String, value: String, isSelectable: Bool = false) {
        self.icon = icon
        self.color = color
        self.label = label
        self.value = value
        self.isSelectable = isSelectable
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Group {
                    if isSelectable {
                        Text(value)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                    } else {
                        Text(value)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        Text("Paper Detail View Preview")
    }
} 