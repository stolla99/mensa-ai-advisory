import SwiftUI
import MapKit

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Über diese App")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            Text("Dies ist eine Mensa App, die über ChatGPT Daten abgreift von einer Mensa Seite um diese dann gut darzustellen und um eine Überischt geben viel Spaß. Bei Fragen einfach melden unter:")
                .padding(.horizontal)
            HStack() {
                Button(action: {
                    let email = "mailto:arne.stoll.1@outlook.de"
                    if let url = URL(string: email) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Email", systemImage: "envelope.fill")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                }
                Link(destination: URL(string: "https://www.linkedin.com/in/arne-stoll-8163321b6/")!) {
                    Label("LinkedIn", systemImage: "link")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                }
            }.padding(.horizontal)
            Text("Danke und viel Spaß mit der App.")
                .padding(.horizontal)
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
