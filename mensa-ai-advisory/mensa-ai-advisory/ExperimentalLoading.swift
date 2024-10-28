import SwiftUI

struct ExperimentalLoading: View {
    @State private var isLoading: Bool = false
    @State private var contentItems: [String] = [] // Example content items, replace with your model

    var body: some View {
        ScrollView {
            if isLoading {
                // Loading indicator view
                VStack {
                    ProgressView("")
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // The content when data is loaded
                LazyVStack(spacing: 0) {
                    ForEach(contentItems.indices, id: \.self) { index in
                        Text(contentItems[index]) // Replace with your content item view
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
        .refreshable {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        await fetchLatestData()
        isLoading = false
    }

    private func fetchLatestData() async {
        // Simulate a network call with delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Simulate a 2 second delay
        // Update content items after loading
        contentItems = ["Item 1", "Item 2", "Item 3"] // Replace with your actual data fetching logic
    }
}

struct ExperimentalLoading_Previews: PreviewProvider {
    static var previews: some View {
        ExperimentalLoading()
    }
}
