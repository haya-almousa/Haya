//
//  HayaApp.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import SwiftUI
import SwiftData

@main
struct HayaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Profile.self,
            Garment.self,
            Outfit.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
