//
//  Persistence.swift
//  GanttFlow
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let sampleTasks: [(String, TaskPriority, Bool, Int, Int, Int16)] = [
            ("Comprar mantimentos", .high, false, -1, 1, 30),
            ("Estudar SwiftUI", .medium, false, 0, 5, 45),
            ("Ligar para o dentista", .low, true, -5, -3, 100),
            ("Preparar apresentação", .high, false, 1, 7, 10),
            ("Fazer exercícios", .medium, true, -3, -1, 100),
            ("Revisar documentação", .medium, false, 3, 10, 0),
        ]

        for (title, priority, completed, startOffset, endOffset, progress) in sampleTasks {
            let task = Item(context: viewContext)
            task.title = title
            task.priority = priority.rawValue
            task.isCompleted = completed
            task.progress = progress
            task.createdAt = Calendar.current.date(byAdding: .day, value: startOffset, to: Date())
            task.startDate = Calendar.current.date(byAdding: .day, value: startOffset, to: Date())
            task.dueDate = Calendar.current.date(byAdding: .day, value: endOffset, to: Date())
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "GanttFlow")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
