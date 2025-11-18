import SwiftUI
import ArxivSwift

struct PaperRowView: View {
    let paper: ArxivEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title
            Text(paper.title)
                .font(.system(.title3, design: .serif))
                .fontWeight(.semibold)
                .lineSpacing(2)
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
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            
            // Footer: Date and Category
            HStack(alignment: .center) {
                Label {
                    Text(formattedDate)
                        .font(.caption)
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "calendar")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                Spacer(minLength: 8)
                
                if let primaryCategory = paper.primaryCategory {
                    let color = categoryColor(primaryCategory.term)
                    Text(primaryCategory.term)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(color.opacity(colorScheme == .dark ? 0.22 : 0.12))
                        )
                        .overlay(
                            Capsule().stroke(color.opacity(0.35), lineWidth: 1)
                        )
                        .foregroundStyle(color)
                        .accessibilityLabel(Text("Category \(primaryCategory.term)"))
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(
            color: (colorScheme == .dark ? .white.opacity(0.05) : .black.opacity(0.08)),
            radius: 10, x: 0, y: 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.06), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
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
    
    private var accessibilitySummary: Text {
        let title = paper.title
        let date = formattedDate
        let category = paper.primaryCategory?.term ?? "uncategorized"
        return Text("\(title), category \(category), published \(date)")
    }
    
    private func categoryColor(_ term: String) -> Color {
        // Map high-level domains to consistent hues
        let top = term.split(separator: ".").first?.lowercased() ?? ""
        switch top {
        case "cs": return .blue
        case "math": return .purple
        case "physics": return .orange
        case "q-bio": return .green
        case "stat": return .teal
        default: return .gray
        }
    }
}
