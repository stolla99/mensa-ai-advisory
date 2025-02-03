import SwiftUI
import MapKit

struct MapView: View {
    var body: some View {
        Map {
            Annotation("Ausgabe 1",
                       coordinate: CLLocationCoordinate2D(
                    latitude: 49.425008457899715,
                    longitude: 7.750306752250873)
            ) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.yellow)
                    Text("🥵")
                        .padding(5)
                }
            }
            Annotation("Ausgabe 2",
                       coordinate: CLLocationCoordinate2D(
                    latitude: 49.424989946043596,
                    longitude: 7.750551178403735)
            ) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.yellow)
                    Text("🤤")
                        .padding(5)
                }
            }
            Annotation("Atrium Cafe",
                       coordinate: CLLocationCoordinate2D(
                    latitude: 49.424812448641084,
                    longitude: 7.750708547815968)
            ) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.yellow)
                    Text("👽")
                        .padding(5)
                }
            }
            Annotation("Bistro 36; † 05/2024",
                       coordinate: CLLocationCoordinate2D(
                    latitude: 49.424429658559866,
                    longitude: 7.753446745476541)
            ) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.yellow)
                    Text("☠️")
                        .padding(5)
                }
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
