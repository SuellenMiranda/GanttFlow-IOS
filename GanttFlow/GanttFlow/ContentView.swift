//
//  ContentView.swift
//  teste
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        TabView {
            TaskListView()
                .tabItem {
                    Label("Tarefas", systemImage: "checklist")
                }

            TaskCalendarView()
                .tabItem {
                    Label("Calendário", systemImage: "calendar")
                }

            GanttView()
                .tabItem {
                    Label("Gantt", systemImage: "chart.bar.xaxis")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
