import SwiftUI

struct ContentTemplateView: View {
    var title: String
    var date: String
    var timestamp: String
    var content: LocalizedStringKey

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
                .padding(.vertical, 10)
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

struct ContentTemplateView_Previews: PreviewProvider {
    static var previews: some View {
        ContentTemplateView(
            title: "SwiftUI Recommendations Recommendations Recommendations",
            date: "October 26, 2024",
            timestamp: "10:00 AM",
            content: """
                import 
                *sd*
                - sdf
                - sdf
                sdf
                sdf
                """
        )
    }
}
