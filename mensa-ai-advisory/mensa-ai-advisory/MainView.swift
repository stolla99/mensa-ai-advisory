//
//  mensa_ai_advisoryApp.swift
//  mensa-ai-advisory
//
//  Created by Arne Stoll on 30.05.24.
//

import SwiftUI

@main
struct MensaAdvisory: App {
    @StateObject private var coreDataStack: CoreDataStack = CoreDataStack.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.persistentContainer.viewContext)
        }
    }
}
