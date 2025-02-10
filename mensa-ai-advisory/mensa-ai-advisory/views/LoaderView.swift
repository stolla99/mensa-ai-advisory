//
//  AnimatedBorderView.swift
//  MensaAdvisory
//
//  Created by Arne Stoll on 2/9/25.
//


import SwiftUI

struct LoaderView: View {
    @State private var rotation: Double = 0.0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 55)
                .stroke(
                    AngularGradient(gradient: Gradient(
                        colors: [
                            .blue, .purple, .pink, .orange, .yellow, .blue
                        ]), center: .center, angle: .degrees(rotation)),
                    lineWidth: 35
                )
                .fill(.ultraThinMaterial)
                .background(Color.white)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .animation(Animation.linear(duration: 3).repeatForever(autoreverses: false), value: rotation)
                .onAppear {
                    rotation = 360
                }.mask(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0),
                            Color.black.opacity(1)  // Fully masked at edges
                        ]),
                        center: .center,
                        startRadius: 0.0,
                        endRadius: UIScreen.main.bounds.width / 1
                    )
                )
        }
        .ignoresSafeArea(.all)
    }
}

struct AnimatedBorderView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Text("Hello World!")
            LoaderView()
        }
        .ignoresSafeArea(.all)
    }
}
