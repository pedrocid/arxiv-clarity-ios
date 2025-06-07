import SwiftUI
import ArxivSwift

struct PaperRowView: View {
    let paper: ArxivEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(paper.title)
                .font(.headline)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // Authors
            Text(authorsText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Published date and categories
            HStack {
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let primaryCategory = paper.primaryCategory {
                    Text(primaryCategory)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var authorsText: String {
        let authors = paper.authors.map { $0.name }
        if authors.count <= 3 {
            return authors.joined(separator: ", ")
        } else {
            return authors.prefix(3).joined(separator: ", ") + " et al."
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: paper.published)
    }
} 