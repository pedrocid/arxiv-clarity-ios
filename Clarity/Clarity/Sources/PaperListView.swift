import SwiftUI
import ArxivKit
import ArxivSwift

struct PaperListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.arxivService) private var arxivService
    
    var body: some View {
        @Bindable var bindableAppState = appState
        
        NavigationStack {
            Group {
                if appState.isLoading {
                    ProgressView("Loading papers...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if appState.papers.isEmpty {
                    ContentUnavailableView(
                        "No Papers Found",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Try adjusting your search or category filter")
                    )
                } else {
                    List(appState.papers, id: \.id) { paper in
                        PaperRowView(paper: paper)
                    }
                    .refreshable {
                        await loadLatestPapers()
                    }
                }
            }
            .navigationTitle("Clarity")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(appState.availableCategories, id: \.0) { category in
                            Button(category.1) {
                                appState.selectedCategory = category.0
                                Task {
                                    await loadLatestPapers()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $bindableAppState.searchText, prompt: "Search papers...")
            .onSubmit(of: .search) {
                Task {
                    await performSearch()
                }
            }
            .task {
                await loadLatestPapers()
            }
            .alert("Error", isPresented: .constant(appState.errorMessage != nil)) {
                Button("OK") {
                    appState.clearError()
                }
            } message: {
                Text(appState.errorMessage ?? "")
            }
        }
    }
    
    @MainActor
    private func loadLatestPapers() async {
        appState.setLoading(true)
        
        do {
            let papers = try await arxivService.getLatest(forCategory: appState.selectedCategory)
            appState.setPapers(papers)
        } catch {
            appState.setError(error)
        }
    }
    
    @MainActor
    private func performSearch() async {
        guard !appState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await loadLatestPapers()
            return
        }
        
        appState.setLoading(true)
        
        do {
            let papers = try await arxivService.performQuery(
                searchQuery: appState.searchText,
                category: appState.selectedCategory,
                sortBy: .relevance,
                sortOrder: .descending
            )
            appState.setPapers(papers)
        } catch {
            appState.setError(error)
        }
    }
} 