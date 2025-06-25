//
//  ThoughtSparkApp.swift
//  ThoughtSpark
//
//  Created by Jonathan Gargano on 6/24/25.
//

import SwiftUI

@main
struct ThoughtSparkApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
