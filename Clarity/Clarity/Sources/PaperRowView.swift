import SwiftUI
import ArxivSwift

struct PaperRowView: View {
    let paper: ArxivEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(paper.title)
                .font(.system(.title3, design: .serif)) // Serif font for academic feel
                .fontWeight(.bold)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Authors
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                
                Text(authorsText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
                .background(Color.primary.opacity(0.1))
            
            // Footer: Date and Category
            HStack {
                Label {
                    Text(formattedDate)
                        .font(.caption)
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "calendar")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                Spacer()
                
                if let primaryCategory = paper.primaryCategory {
                    Text(primaryCategory.term)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.1)
                        )
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                Color(.systemBackground)
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [Color.blue.opacity(0.02), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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