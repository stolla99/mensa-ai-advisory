//
//  ContentView.swift
//  mensa-ai-advisory
//
//  Created by Arne Stoll on 30.05.24.
//

import SwiftUI

struct MenuItem {
    let iconName: String
    let title: String
}

enum ModalType {
    case error
    case yesNo
    case okOnly
    
}

struct AlertDetails: Identifiable {
    let modalType: ModalType
    let errorDescription: String
    let queryDate: Date
    let id = UUID()
}

let menuItems = [
    MenuItem(iconName: "bubble.right.fill", title: "Today"),
    MenuItem(iconName: "flask.fill", title: "Experimental"),
    MenuItem(iconName: "gearshape.fill", title: "Settings"),
    MenuItem(iconName: "info.circle.fill", title: "About")
]

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var sharedData = CoreDataStack.shared
    
    @StateObject private var webFetcher = WebpageFetcher()
    @StateObject private var openAiFetcher = OpenAiFetcher()
    
    @State private var isShowingAlert: Bool = false
    @State private var details: AlertDetails = AlertDetails(modalType: .error, errorDescription: "Default", queryDate: Date.distantPast)
    @State private var alertMessage: String = ""
    @State private var overrideOnce: Bool = false
    
    @State private var activeMenu: String = "Today"
    
    let mealTemplate = """
        **{title}** 
        *{explanation}* • *{price}*
        \n
        """
    
    private func retrieveLatestMensaData(queryDate: Date) async -> MealResponse {
        do {
            try await webFetcher.fetchData(date: queryDate)
            let content: String = webFetcher.responseStrings.joined(separator: "\n")
            let (runThreadJson, _): ([String: Any], Data) = try await openAiFetcher.createAndRunThread(content: content)
            
            let threadId: String = runThreadJson["thread_id"] as! String
            let runId: String = runThreadJson["id"] as! String
            try await openAiFetcher.pollUntilStatusCompleted(threadId: threadId, runId: runId, interval: 1)
            // let threadId: String = "thread_KW4VFQK4vzyyTqkxK71br2RS"
            let (messagesJson, _): ([String: Any], Data) = try await openAiFetcher.retrieveMessages(threadId: threadId)
            let responseJson: MealResponse = try openAiFetcher.parseMessages(messages: messagesJson)
            return responseJson
        } catch {
            return MealResponse(meals: [], comment: "An error occurred: \(error.localizedDescription)", funny_title: "Error")
        }
    }
    
    private func getCurrentDateAndTime(currentDate: Date) -> (date: String, timestamp: String) {
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = TimeZone.current

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current 
        
        return (date: dateFormatter.string(from: currentDate), timestamp: timeFormatter.string(from: currentDate))
    }
    
    private func mapMensaDayToContentTemplateView(mensaDay: MensaDay) -> ContentTemplateView {
        let (date, timestamp) = getCurrentDateAndTime(currentDate: mensaDay.date ?? Date())
        let meals: [Meal] = mensaDay.meals?.allObjects as? [Meal] ?? []
        var content = ""
        for meal: Meal in meals {
            content.append(mealTemplate
                .replacingOccurrences(of: "{title}", with: meal.title ?? "")
                .replacingOccurrences(of: "{explanation}", with: meal.explanation ?? "")
                .replacingOccurrences(of: "{price}", with: meal.price ?? "")
            )
        }
        content.append(mensaDay.comment ?? "")
        
        let newContent = ContentTemplateView(
            title: mensaDay.funny_title ?? "",
            date: date,
            timestamp: timestamp,
            content: LocalizedStringKey.init(content)
        )
        return newContent
    }
    
    func mapMensaDaysToMealResponses(mensaDays: [MensaDay]) -> [MealResponse] {
        return mensaDays.map {
            let meals: [MealResponse.MealData] = $0.meals?.allObjects as? [MealResponse.MealData] ?? []
            let mealResponse = MealResponse(
                meals: meals.map {
                    return MealResponse.MealData(title: $0.title, explanation: $0.explanation, price: $0.price)
                },
                comment: $0.comment ?? "-",
                funny_title: $0.funny_title ?? "-"
            )
            return mealResponse
        }
    }
    
    private func fetchLatestData(queryDate: Date) async -> Int {
        let newMealResponse: MealResponse = await retrieveLatestMensaData(queryDate: queryDate)
        sharedData.add(mealResponse: newMealResponse)
        return 1
    }
    
    func isPastTwoPM(on date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var twoPMComponents = components
        twoPMComponents.hour = 14
        twoPMComponents.minute = 0
        twoPMComponents.second = 0
        guard let twoPMDate = calendar.date(from: twoPMComponents) else {
            return false
        }
        return date > twoPMDate
    }

    
    private func decidingNextStep(on queryDate: Date) async -> (isAlert: Bool, title: String, message: String, date: Date, type: ModalType) {
        let alreadyCheckedToday: Bool = sharedData.mensaDays.map {
            return Calendar.current.isDate(queryDate, inSameDayAs: $0.date ?? Date.distantPast)
        }.reduce(false, { $0 || $1 })
        
        if alreadyCheckedToday {
            if isPastTwoPM(on: queryDate) {
                return (
                    true,
                    "Information",
                    "Want to check for tomorrow? If yes next refresh will trigger the fetch data for tomorrow",
                    Calendar.current.date(byAdding: .day, value: 1, to: queryDate) ?? Date.distantPast,
                    .yesNo
                )
            } else {
                return (
                    true,
                    "Proceed?",
                    "You already checked the menu today. If proceeding next refresh will trigger the update regardless",
                    queryDate,
                    .yesNo
                )
            }
        } else {
            return (
                false,
                "",
                "",
                queryDate,
                .okOnly
            )
        }
    }

    var body: some View {
        VStack {
            if activeMenu == "Today" {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sharedData.mensaDays, id: \.self) { elem in
                            mapMensaDayToContentTemplateView(mensaDay: elem)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                        }
                    }
                }
                .refreshable {
                    let currentDate = Date()
                    
                    var (alertShowing, title, message, queryDate, type) = await decidingNextStep(on: currentDate)
                    if overrideOnce {
                        alertShowing = false
                        title = ""
                        message = ""
                    }
                    
                    if !alertShowing || overrideOnce {
                        overrideOnce = false
                        let task = Task {
                            await fetchLatestData(queryDate: queryDate)
                        }
                        _ = await task.value
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isShowingAlert = alertShowing
                        alertMessage = title
                        details = AlertDetails(modalType: type, errorDescription: message, queryDate: queryDate)
                    }
                }
                .alert(
                    alertMessage,
                    isPresented: $isShowingAlert,
                    presenting: details
                ) { details in
                    switch details.modalType {
                        case .yesNo:
                        Button("No",  role: .cancel) {
                                // Replace
                        }
                        Button("Yes") {
                            overrideOnce = true
                        }
                        default:
                            Button("Ok") {}
                    }
                } message: { details in
                    return Text(details.errorDescription + "(" + {
                        let formatter = DateFormatter()
                        formatter.dateFormat =  "dd.MM.yyyy"
                        return formatter.string(from: details.queryDate)
                    }() + ")")
                }
            } else if activeMenu == "Experimental" {
                Text("Experimental")
            } else if activeMenu == "Settings" {
                Text("Settings")
            } else if activeMenu == "About" {
                Text("About")
            }
        }
        .frame(maxWidth: .infinity)
        Spacer()
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                ForEach(menuItems, id: \.title) { item in
                    Button(action: {
                        
                        activeMenu = item.title
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: item.iconName)
                                .imageScale(.large)
                                .frame(height: 26)
                                .clipped()
                            Text(item.title)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .frame(height: 50)
                        .clipped()
                        .foregroundStyle(.primary)
                        .foregroundColor(activeMenu == item.title ? .blue : .gray )
                    }
                }
            }
            .padding(5)
        }
        .frame(height: 60, alignment: .bottom)
        .clipped()
    }
}

#Preview {
    ContentView()
}
