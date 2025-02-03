//
//  CustomRowView.swift
//  MensaAdvisory
//
//  Created by Arne Stoll on 2/3/25.
//


import SwiftUI

struct CustomRowView: View {
    let title: String
    let date: String
    let timestamp: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(-20)
            Text(date + " • " + timestamp)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.vertical, 5)
            Text(content)
                .font(.body)
        }
        .padding()
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.gray).opacity(0.1))
        )
    }
}

struct CCContentView: View {
    var body: some View {
        List {
            CustomRowView(
                title: "Hello, World!",
                date: "Feb 3, 2025",
                timestamp: "10:00 AM",
                content: "This is an example of a custom row view."
            )
            CustomRowView(
                title: "Hello, World!",
                date: "Feb 3, 2025",
                timestamp: "10:00 AM",
                content: "This is an example of a custom row view."
            )
        }
        .listStyle(PlainListStyle())
    }
}

struct CCContentView_Previews: PreviewProvider {
    static var previews: some View {
        CCContentView()
    }
}
