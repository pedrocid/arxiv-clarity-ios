import SwiftUI
import ArxivKit
import ArxivSwift

struct PaperListView: View {
    @Environment(\.appState) private var appState
    @Environment(\.arxivService) private var arxivService
    @Bindable private var bindableAppState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    init() {
        @Environment(\.appState) var appState
        self.bindableAppState = appState
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean, native background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                Group {
                    if appState.isLoading {
                        // Placeholder skeletons for a faster perceived load
                        ScrollView {
                            VStack(spacing: 0) {
                                CategoryChipsRow(selected: appState.selectedCategory, categories: appState.availableCategories) { newCategory in
                                    appState.selectedCategory = newCategory
                                }
                                .padding(.top, 4)
                                .padding(.bottom, 4)

                                ForEach(0..<6, id: \.self) { _ in
                                    SkeletonRow()
                                }
                            }
                        }
                        .redacted(reason: .placeholder)
                        .transition(.opacity)
                    } else if appState.papers.isEmpty && appState.errorMessage == nil {
                        VStack(spacing: 24) {
                            if appState.searchText.isEmpty {
                                // Welcome state when no search is active
                                Image("welcome-illustration")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150, height: 150)
                                    .opacity(0.9)
                                
                                VStack(spacing: 8) {
                                    Text("Welcome to Clarity")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Discovering interesting papers...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                // Empty search results state
                                Image("empty-state")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 120, height: 120)
                                    .opacity(0.8)
                                
                                VStack(spacing: 8) {
                                    Text("No Results Found")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Try adjusting your search terms or browse different categories")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding()
                        .transition(.opacity)
                    } else if let errorMessage = appState.errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text("Error")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(errorMessage)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Retry") {
                                Task {
                                    await loadDefaultPapers()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top)
                        }
                        .padding()
                    } else {
                        VStack(spacing: 0) {
                            CategoryChipsRow(selected: appState.selectedCategory, categories: appState.availableCategories) { newCategory in
                                appState.selectedCategory = newCategory
                                Task {
                                    if appState.searchText.isEmpty {
                                        await loadDefaultPapers()
                                    } else {
                                        await performSearch()
                                    }
                                }
                            }
                            .padding(.vertical, 4)

                            List(appState.papers, id: \.id) { paper in
                                NavigationLink(destination: PaperDetailView(paper: paper)) {
                                    PaperRowView(paper: paper)
                                        .listRowInsets(EdgeInsets())
                                        .listRowSeparator(.hidden)
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .refreshable {
                                if appState.searchText.isEmpty {
                                    await loadDefaultPapers()
                                } else {
                                    await performSearch()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("ArXiv Papers")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $bindableAppState.searchText, prompt: "Search papers...")
            .onSubmit(of: .search) {
                Task {
                    await performSearch()
                }
            }
            .searchSuggestions {
                ForEach(appState.availableCategories, id: \.0) { _, name in
                    Text(name).searchCompletion(name)
                }
            }
            .onChange(of: appState.searchText) { oldValue, newValue in
                if newValue.isEmpty && !oldValue.isEmpty {
                    // User cleared search, reload default papers
                    Task {
                        await loadDefaultPapers()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(appState.availableCategories, id: \.0) { category, name in
                            Button(action: {
                                appState.selectedCategory = category
                                Task {
                                    if appState.searchText.isEmpty {
                                        await loadDefaultPapers()
                                    } else {
                                        await performSearch()
                                    }
                                }
                            }) {
                                HStack {
                                    Text(name)
                                    if appState.selectedCategory == category {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .task {
            // Load interesting papers when the app opens
            await loadDefaultPapers()
        }
    }
    
    @MainActor
    private func loadDefaultPapers() async {
        print("🚀 PaperListView: Loading default papers")
        appState.setLoading(true)
        
        do {
            // Load interesting papers for a diverse and engaging experience
            let papers = try await arxivService.getInterestingPapers(maxResults: 20)
            appState.setPapers(papers)
        } catch {
            print("❌ PaperListView: Error loading default papers: \(error)")
            appState.setError(error)
        }
    }
    
    @MainActor
    private func performSearch() async {
        guard !appState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await loadDefaultPapers()
            return
        }
        
        print("🔍 PaperListView: Performing search for: '\(appState.searchText)'")
        appState.setLoading(true)
        
        do {
            let papers = try await arxivService.performQuery(
                searchQuery: appState.searchText,
                category: appState.selectedCategory,
                maxResults: 50
            )
            appState.setPapers(papers)
        } catch {
            print("❌ PaperListView: Error performing search: \(error)")
            appState.setError(error)
        }
    }
}

// MARK: - Helper Views
private func categoryColor(_ term: String) -> Color {
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

private struct CategoryChipsRow: View {
    let selected: String
    let categories: [(String, String)]
    var onSelect: (String) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.0) { cat, name in
                    let color = categoryColor(cat)
                    Button(action: { onSelect(cat) }) {
                        Text(name)
                            .font(.caption).fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(
                                    selected == cat
                                    ? color.opacity(colorScheme == .dark ? 0.28 : 0.18)
                                    : Color.secondary.opacity(colorScheme == .dark ? 0.10 : 0.08)
                                )
                            )
                            .overlay(
                                Capsule().stroke(
                                    (selected == cat ? color : Color.secondary).opacity(0.35), lineWidth: 1
                                )
                            )
                            .foregroundStyle(selected == cat ? color : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .accessibilityLabel("Categories")
    }
}

private struct SkeletonRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Title placeholder\nline two")
                .font(.title3).fontWeight(.semibold)
                .lineLimit(2)
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill").font(.caption)
                Text("Author names placeholder")
                    .font(.callout)
            }
            HStack {
                Label("Date", systemImage: "calendar").font(.caption)
                Spacer()
                Text("cs.AI").font(.caption)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    PaperListView()
        .environment(\.appState, AppState())
        .environment(\.arxivService, ArxivService())
} 
