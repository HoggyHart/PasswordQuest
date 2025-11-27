//
//  PQPrototypeApp.swift
//  PQPrototype
//
//  Created by William Hart on 27/11/2025.
//

import SwiftUI

@main
struct PQPrototypeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
