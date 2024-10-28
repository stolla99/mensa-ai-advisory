import SwiftUI
import OpenAI
import Alamofire
import SwiftSoup

class WebpageFetcher: ObservableObject {
    @State var url: String = "https://www.mensa-kl.de"
    @State var dateFormat: String = "dd.MM.yyyy"
    @State var todayNoMensaDialog: String = "Heute gibt es keine Mensa. Somit auch keine Essens-Angebote."
    
    @Published var responseStrings: [String] = []
    
    func fetchData(date: Date) async throws -> Void {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
         
        do {
            let response = try await AF.request(url)
                .validate()
                .serializingString()
                .value
            
            let paragraphs = try SwiftSoup.parse(response).body()!.select("div.week0#day")
            var responseList: [String] = []
            for paragraph in paragraphs {
                let content = try paragraph.text()
                
                let dateString = formatter.string(from: date)
                // let dateString = "29.10.2024"
                let additionalFilter = "Abendmensa"
                if content.range(of: dateString, options: .regularExpression) != nil && !(content.range(of: additionalFilter, options: .regularExpression) != nil)
                {
                    responseList.append(content)
                }
            }
            
            if responseList.isEmpty {
                responseList.append(todayNoMensaDialog)
            }
            
            let finalList = responseList
            DispatchQueue.main.async {
                self.responseStrings = finalList
            }
        } catch {
            DispatchQueue.main.async {
                self.responseStrings = ["Error fetching data: \(error.localizedDescription)"]
            }
        }
    }
}
