import SwiftUI
import ArxivKit
import ArxivSwift

struct PaperListView: View {
    @Environment(\.appState) private var appState
    @Environment(\.arxivService) private var arxivService
    @Bindable private var bindableAppState: AppState
    
    init() {
        @Environment(\.appState) var appState
        self.bindableAppState = appState
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle background pattern
                Image("background-pattern")
                    .resizable(resizingMode: .tile)
                    .opacity(0.03)
                    .ignoresSafeArea()
                
                Group {
                    if appState.isLoading {
                        VStack(spacing: 20) {
                            Image("loading-state")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                            
                            ProgressView()
                            
                            Text("Loading papers...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Discovering the latest research...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if appState.papers.isEmpty && appState.errorMessage == nil {
                        VStack(spacing: 20) {
                            if appState.searchText.isEmpty {
                                // Welcome state when no search is active
                                Image("welcome-illustration")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150, height: 150)
                                
                                Text("Welcome to Clarity")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Discovering interesting papers...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                // Empty search results state
                                Image("empty-state")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 120, height: 120)
                                
                                Text("No Results Found")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Try adjusting your search terms or browse different categories")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
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
                        List(appState.papers, id: \.id) { paper in
                            NavigationLink(destination: PaperDetailView(paper: paper)) {
                                PaperRowView(paper: paper)
                            }
                        }
                        .refreshable {
                            if appState.searchText.isEmpty {
                                await loadDefaultPapers()
                            } else {
                                await performSearch()
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("ArXiv Papers")
            .searchable(text: $bindableAppState.searchText, prompt: "Search papers...")
            .onSubmit(of: .search) {
                Task {
                    await performSearch()
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

#Preview {
    PaperListView()
        .environment(\.appState, AppState())
        .environment(\.arxivService, ArxivService())
} 