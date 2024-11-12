//
//  ContentView.swift
//  mensa-ai-advisory
//
//  Created by Arne Stoll on 30.05.24.
//

import SwiftUI

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
    @State private var details: AlertDetails = AlertDetails(modalType: ModalType.error, errorDescription: "Default", queryDate: Date.distantPast)
    @State private var alertMessage: String = ""
    @State private var overrideOnce: Bool = false
    
    @State private var activeMenu: String = "Today"
    
    let formatter = DateFormatter()
    
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
    
    private func fetchLatestData(queryDate: Date) async -> Int {
        let newMealResponse: MealResponse = await retrieveLatestMensaData(queryDate: queryDate)
        sharedData.add(mealResponse: newMealResponse)
        return 1
    }

    var body: some View {
        VStack {
            if activeMenu == "Today" {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sharedData.mensaDays, id: \.self) { elem in
                            mapMensaDayToContentTemplateView(mensaDay: elem, with: mealTemplate)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                        }
                    }
                }
                .refreshable {
                    let currentDate = Date()
                    
                    var (alertShowing, title, message, queryDate, type) = await decidingNextStep(on: currentDate, on: sharedData)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
