import SwiftUI
import ArxivSwift

struct PaperRowView: View {
    let paper: ArxivEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(paper.title)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)
            
            // Authors
            Text(authorsText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Published date and categories
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let primaryCategory = paper.primaryCategory {
                    Text(primaryCategory.term)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
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