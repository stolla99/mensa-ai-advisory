import SwiftUI

// Model for a message.
struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

// The view that displays a single message.
struct MessageView: View {
    let message: Message
    // A callback closure to inform the parent view that this message should be removed.
    let onDelete: (Message) -> Void

    var body: some View {
        HStack {
            Text(message.text)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.3))
        .cornerRadius(8)
        // Attach swipe actions to the row.
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete(message)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            // If you want to add additional actions, you can do so here:
            // Button {
            //     // Add more action code here.
            // } label: {
            //     Label("More", systemImage: "ellipsis")
            // }
            // .tint(.blue)
        }
    }
}

// The parent view that holds the list of messages.
struct TTContentView: View {
    @State private var messages: [Message] = [
        Message(text: "Hello, World!"),
        Message(text: "Welcome to SwiftUI."),
        Message(text: "Swipe to delete!")
    ]

    var body: some View {
        VStack {
            List {
                ForEach(messages) { message in
                    MessageView(message: message, onDelete: removeMessage)
                }
            }
            .listStyle(PlainListStyle())
            
            // Optional button to add new messages.
            Button("Add Message") {
                let newMessage = Message(text: "New message at \(Date())")
                messages.append(newMessage)
            }
            .padding()
        }
    }
    
    // Removes a message from the array.
    func removeMessage(_ message: Message) {
        if let index = messages.firstIndex(of: message) {
            messages.remove(at: index)
        }
    }
}

struct TTContentView_Previews: PreviewProvider {
    static var previews: some View {
        TTContentView()
    }
}
