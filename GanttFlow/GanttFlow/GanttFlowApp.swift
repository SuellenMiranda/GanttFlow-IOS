//
//  GanttFlowApp.swift
//  GanttFlow
//
//  Created by Suellen Miranda on 25/06/26.
//

import SwiftUI
import CoreData

@main
struct GanttFlowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
