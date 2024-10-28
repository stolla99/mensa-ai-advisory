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

let menuItems = [
    MenuItem(iconName: "bubble.right.fill", title: "Today"),
    MenuItem(iconName: "flask.fill", title: "Experimental"),
    MenuItem(iconName: "gearshape.fill", title: "Settings"),
    MenuItem(iconName: "info.circle.fill", title: "About")
]

struct ContentView: View {
    @StateObject private var webFetcher = WebpageFetcher()
    @StateObject private var openAiFetcher = OpenAiFetcher()
    
    @State private var activeMenu: String = "Today"
    @State private var contentItems = [
        ContentTemplateView(
            title: "looooooooooooooong lo lo lo looooooooooooooong title",
            date: "October 26, 2024",
            timestamp: "10:00 AM",
            content: """
            **looooooooooooooong title** 
            *explanation* • *price*
            
            **title** 
            *explanation* • *price*
            \n
            summary
            """
        )
    ]
    
    let mealTemplate = """
        **{title}** 
        *{explanation}* • *{price}*
        \n
        """
    
    private func retrieveLatestMensaData() async -> MealResponse {
        do {
            try await webFetcher.fetchData(date: Date())
            let content: String = webFetcher.responseStrings.joined(separator: "\n")
            let (runThreadJson, _): ([String: Any], Data) = try await openAiFetcher.createAndRunThread(content: content)
            
            let threadId: String = runThreadJson["thread_id"] as! String
            let runId: String = runThreadJson["id"] as! String
            try await openAiFetcher.pollUntilStatusCompleted(threadId: threadId, runId: runId, interval: 1)
            let (messagesJson, _): ([String: Any], Data) = try await openAiFetcher.retrieveMessages(threadId: threadId)
            let responseJson: MealResponse = try openAiFetcher.parseMessages(messages: messagesJson)
            return responseJson
        } catch {
            return MealResponse(meals: [], comment: "An error occurred: \(error.localizedDescription)", funny_title: "Error")
        }
    }
    
    private func smoothDecrease(ratio: Double) -> Double {
        let lower = 0.7
        let minScale = 0.3
        if ratio <= lower {
            return 1.0
        } else if ratio <= 1.0 {
            let t = (ratio - lower) / 0.2
            return 1.0 - minScale * t * t
        } else {
            return minScale
        }
    }
    
    private func getCurrentDateAndTim() -> (date: String, timestamp: String) {
        let currentDate = Date()
        
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
    
    private func fetchLatestData() async -> Int {
        let historyCount = 30
        
        let newMealResponse: MealResponse = await retrieveLatestMensaData()
        
        let (date, timestamp) = getCurrentDateAndTim()
        var content = ""
        for meal: MealResponse.Meal in newMealResponse.meals {
            content.append(mealTemplate
                .replacingOccurrences(of: "{title}", with: meal.title)
                .replacingOccurrences(of: "{explanation}", with: meal.explanation)
                .replacingOccurrences(of: "{price}", with: meal.price)
            )
        }
        content.append(newMealResponse.comment)
        
        let newContent = ContentTemplateView(
            title: newMealResponse.funny_title,
            date: date,
            timestamp: timestamp,
            content: LocalizedStringKey.init(content)
        )
        
        contentItems.insert(newContent, at: 0)
        if (contentItems.count > historyCount) {
            contentItems.removeLast()
        }
        return 1
    }

    var body: some View {
        VStack {
            if activeMenu == "Today" {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(contentItems.indices, id: \.self) { index in
                            contentItems[index]
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                        }
                    }
                }
                .refreshable {
                    let task = Task {
                        await fetchLatestData()
                    }
                    let result = await task.value
                    print(result)
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
