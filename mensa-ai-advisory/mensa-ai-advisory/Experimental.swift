import SwiftUI

struct ContentView2: View {
    @State private var contentItems = (1...20).map { "Item \($0)" }
    var body: some View {
        NavigationStack {
            List {
                ForEach(contentItems.indices, id: \.self) { index in
                    Text(contentItems[index])
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            print("Muting conversation")
                        } label: {
                            Label("Mute", systemImage: "bell.slash.fill")
                        }
                        .tint(.indigo)
                        
                        Button(role: .destructive) {
                            print("Deleting conversation")
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                        
                }
            }
        }
    }
}

struct ContentView2_Previews: PreviewProvider {
    static var previews: some View {
        ContentView2()
    }
}
