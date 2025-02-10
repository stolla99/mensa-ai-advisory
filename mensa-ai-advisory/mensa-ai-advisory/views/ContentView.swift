//
//  ContentView.swift
//  mensa-ai-advisory
//
//  Created by Arne Stoll on 30.05.24.
//

import SwiftUI

let menuItems = [
    MenuItem(iconName: "bubble.right.fill", title: "Today"),
    MenuItem(iconName: "map.fill", title: "Karte"),
    MenuItem(iconName: "gearshape.fill", title: "Settings"),
    MenuItem(iconName: "info.circle.fill", title: "About")
]

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject private var sharedData = CoreDataStack.shared
    
    @StateObject private var webFetcher = WebpageFetcher()
    @StateObject private var openAiFetcher = OpenAiFetcher()
    
    @State private var tempData: [AlertDetails] = []
    @State private var isShowingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var overrideOnce: Bool = false
    @State private var activeMenu: String = "Today"
    @State private var isViewingKey: Bool = false
    @State private var keyMask: String = (retrieveKey(key: "OPENAIKEY") ?? "*empty*").map {_ in "*" }.joined()
    @State private var enforceRefresh = false
    
    @State private var isValidKey = false
    
    @State private var isLoading = false
    @State private var rotation: Double = 0.0
    @State private var showAlert: Bool = false
    
    private var alertBinding: Binding<Bool> {
        Binding(
            get: { showAlert && !isLoading },
            set: { newValue in showAlert = newValue }
        )
    }
    @State private var showValidationError = false
    
    private var shouldShowAlert: Bool {
        showAlert && !isLoading
    }
    
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
            // let threadId: String = "thread_zR46Qb7ozsC8iunPI9U82sIl"
            let (messagesJson, _): ([String: Any], Data) = try await openAiFetcher.retrieveMessages(threadId: threadId)
            let responseJson: MealResponse = try openAiFetcher.parseMessages(messages: messagesJson)
            return responseJson
        } catch {
            return MealResponse(meals: [], comment: "An error occurred: \(error.localizedDescription)", funny_title: "Error")
        }
    }
    
    private func fetchLatestData(queryDate: Date) async -> Int {
        let newMealResponse: MealResponse = await retrieveLatestMensaData(queryDate: queryDate)
        sharedData.add(mealResponse: newMealResponse, queryDate: queryDate)
        return 1
    }
    
    func removeAlertDetails(_ alertDetails: AlertDetails) {
        if let index = tempData.firstIndex(of: alertDetails) {
            tempData.remove(at: index)
        }
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                VStack {
                    VStack {
                        if activeMenu == "Today" {
                            VStack(spacing: 0) {
                                List {
                                    ForEach(tempData, id: \.id) { elem in
                                        AlertTemplateView(element: elem, onDelete: removeAlertDetails)
                                            .padding(.vertical, -10)
                                            .padding(.horizontal, -10)
                                    }
                                    .listRowSeparator(.hidden)
                                    ForEach(sharedData.mensaDays, id: \.self) { elem in
                                        mapMensaDayToContentTemplateView(mensaDay: elem, with: mealTemplate)
                                            .padding(.vertical, -10)
                                            .padding(.horizontal, -10)
                                    }
                                    .listRowSeparator(.hidden)
                                }
                                .listStyle(PlainListStyle())
                            }
                            .refreshable {
                                isLoading = true
                                if !isValidKey {
                                    isValidKey = await openAiFetcher.validateApiKey()
                                    if !isValidKey {
                                        showAlert = true
                                    }
                                }
                                if isValidKey {
                                    let currentDate = Date()
                                    if !enforceRefresh {
                                        let (alertShowing, title, message, queryDate, _) = await decidingNextStep(on: currentDate, on: sharedData)
                                        tempData.append(AlertDetails(title: title, errorDescription: message, intentAlert: alertShowing))
                                        if !alertShowing {
                                            let task = Task {
                                                await fetchLatestData(queryDate: queryDate)
                                            }
                                            _ = await task.value
                                        }
                                    } else {
                                        let task = Task {
                                            await fetchLatestData(queryDate: currentDate)
                                        }
                                        _ = await task.value
                                    }
                                }
                                isLoading = false
                            }
                            .alert("Der API key den sie angegeben haben ist nicht gültig.", isPresented: alertBinding) {
                                Button("Weiter") {
                                    
                                }
                                Button("Setzen") {
                                    activeMenu = "Settings"
                                }
                            }
                        } else if activeMenu == "Karte" {
                            MapView()
                        } else if activeMenu == "Settings" {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Open AI Key")
                                    .font(.title2)
                                    .bold()
                                    .padding(.horizontal)
                                Text("Gib hier deinen OpenAI API Key ein, um die KI-Funktionen zu aktivieren. Stelle sicher, dass der Key gültig ist und über die erforderlichen Berechtigungen verfügt.")
                                    .padding(.horizontal)
                                Text(keyMask)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.gray)
                                    .lineLimit(4)
                                    .frame(height: UIFont.preferredFont(forTextStyle: .body).lineHeight * 4)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                HStack() {
                                    PasteButton(payloadType: String.self) { strings in
                                        let copy: String = strings[0]
                                        let sucess = storeKey(key: "OPENAIKEY", value: strings[0])
                                        isViewingKey = false
                                        Task {
                                            isValidKey = await openAiFetcher.validateApiKey()
                                        }
                                        keyMask = !sucess ? "*err*" : copy.map {_ in "*" }.joined()
                                    }
                                    .labelStyle(.titleOnly)
                                    .padding(.leading)
                                    .disabled(isLoading)
                                    Button(action: {
                                        if isViewingKey {
                                            isViewingKey = false
                                            keyMask = keyMask.map {_ in "*" }.joined()
                                        } else {
                                            isViewingKey = true
                                            keyMask = retrieveKey(key: "OPENAIKEY") ?? "*empty*"
                                        }
                                    }) {
                                        Label("View", systemImage: isViewingKey ? "eye.slash" : "eye.fill")
                                            .foregroundStyle(isViewingKey ? Color.accentColor : Color.gray)
                                        
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color.gray.opacity(0.2))
                                    .disabled(isLoading)
                                    Button(action: {
                                        if !isValidKey {
                                            isLoading = true
                                            Task {
                                                isValidKey = await openAiFetcher.validateApiKey()
                                                isLoading = false
                                            }
                                        }
                                    }) {
                                        Label("Validieren", systemImage: isValidKey ? "checkmark" : "xmark")
                                            .foregroundStyle(isValidKey ? Color.accentColor : Color.red)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color.gray.opacity(0.2))
                                    .disabled(isLoading)
                                }
                                Text("Allgemeines")
                                    .font(.title2)
                                    .bold()
                                    .padding(.horizontal)
                                Text("Stelle hier generelle Funtionen ein um das Anwendungs Erlebnis zu verbessern.")
                                    .padding(.horizontal)
                                Toggle(isOn: $enforceRefresh) {
                                    Text("Aktualisierung erzwingen")
                                }
                                .padding(.horizontal)
                                Text("Alle Informationen löschen, es werden alle Daten entfernt inklusive der App-Settings.")
                                    .padding(.horizontal)
                                Button(action: {
                                    showValidationError = true
                                }) {
                                    Label("Alle Daten löschen", systemImage: "trash.fill")
                                        .foregroundStyle(Color.red)
                                }
                                .alert("Möchten sie alle Daten wirklich löschen?", isPresented: $showValidationError) {
                                    Button("Löschen", role: .destructive) {
                                        // Only delete data
                                        CoreDataStack.shared.deleteAll()
                                    }
                                    Button("Abbrechen", role: .cancel) {
                                        // EMPTY
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.gray.opacity(0.1))
                                .padding(.horizontal)
                            }
                        } else if activeMenu == "About" {
                            AboutView()
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
                                    .foregroundColor(activeMenu == item.title ? Color.accentColor : .gray)
                                }
                            }
                        }
                        .padding(5)
                    }
                    .frame(height: 60, alignment: .bottom)
                    .clipped()
                }
                .padding(.top, proxy.safeAreaInsets.top + 60)
                .padding(.bottom, proxy.safeAreaInsets.bottom + 35)
            }
            .ignoresSafeArea(.all)
        }
        .overlay {
            if isLoading {
                LoaderView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
