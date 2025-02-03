//
//  SwipeableView.swift
//  MensaAdvisory
//
//  Created by Arne Stoll on 2/3/25.
//


import SwiftUI

struct SwipeableView: View {
    @State private var offset: CGFloat = 0.0
    @GestureState private var dragOffset: CGFloat = 0.0

    var body: some View {
        Text("Swipe Me")
            .padding()
            .background(Color.blue.opacity(0.7))
            .cornerRadius(8)
            // Combine the current offset with the gesture's temporary translation
            .offset(x: offset + dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        // Update gesture state as the view is dragged
                        state = value.translation.width
                    }
                    .onEnded { value in
                        // Determine action based on drag amount
                        if value.translation.width > 100 {
                            // For example, swipe right enough to trigger an action
                            offset = 200
                            print("Swiped Right!")
                        } else if value.translation.width < -100 {
                            // Or swipe left to trigger a different action
                            offset = -200
                            print("Swiped Left!")
                        } else {
                            // Not enough swiping – reset the offset
                            offset = 0
                        }
                    }
            )
            .animation(.easeInOut, value: offset)
    }
}

struct SSContentView: View {
    var body: some View {
        VStack {
            Spacer()
            SwipeableView()
            Spacer()
        }
    }
}

struct SSContentView_Previews: PreviewProvider {
    static var previews: some View {
        SSContentView()
    }
}
