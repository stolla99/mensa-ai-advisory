import SwiftUI

struct ContentView2: View {
    @State private var contentItems = (1...20).map { "Item \($0)" }
    @State private var scale = 1.0
    
    func smoothDecrease(x: Double) -> Double {
        let lower = 0.7
        let minScale = 0.3
        if x <= lower {
            return 1.0
        } else if x <= 1.0 {
            let t = (x - lower) / 0.2
            return 1.0 - minScale * t * t
        } else {
            return minScale
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(contentItems.indices, id: \.self) { index in
                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY
                        let height = UIScreen.main.bounds.height
                        let scale = smoothDecrease(x: minY / height)
                        
                        Text(contentItems[index])
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .scaleEffect(max(scale, 0.75))
                            .animation(.easeInOut, value: minY)
                    }
                    .frame(height: 100)
                }
            }
        }
        .refreshable {
            fetchLatestData()
        }
    }
    
    func fetchLatestData() {
        // Placeholder for fetching data logic
        contentItems.append("New Item \(contentItems.count + 1)")
    }
}

struct ContentView2_Previews: PreviewProvider {
    static var previews: some View {
        ContentView2()
    }
}
