//
//  TaskListView.swift
//  teste
//

import SwiftUI
import CoreData

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "Todas"
    case pending = "Pendentes"
    case completed = "Concluídas"

    var id: String { rawValue }
}

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Item.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false),
            NSSortDescriptor(keyPath: \Item.createdAt, ascending: false)
        ],
        animation: .default)
    private var tasks: FetchedResults<Item>

    @State private var filter: TaskFilter = .all
    @State private var showingAddTask = false
    @State private var taskToEdit: Item?

    private var filteredTasks: [Item] {
        switch filter {
        case .all:
            return Array(tasks)
        case .pending:
            return tasks.filter { !$0.isCompleted }
        case .completed:
            return tasks.filter { $0.isCompleted }
        }
    }

    private var pendingCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !tasks.isEmpty {
                    Picker("Filtro", selection: $filter) {
                        ForEach(TaskFilter.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                if filteredTasks.isEmpty {
                    ContentUnavailableView {
                        Label("Nenhuma tarefa", systemImage: "checklist")
                    } description: {
                        Text(emptyStateMessage)
                    } actions: {
                        Button("Adicionar tarefa") {
                            showingAddTask = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            taskRow(task)
                        }
                        .onDelete(perform: deleteTasks)
                    }
#if os(iOS)
                    .listStyle(.insetGrouped)
#else
                    .listStyle(.inset)
#endif
                }
            }
            .navigationTitle("Minhas Tarefas")
            .toolbar {
#if os(iOS)
                if !filteredTasks.isEmpty {
                    ToolbarItem(placement: .automatic) {
                        EditButton()
                    }
                }
#endif
                ToolbarItem(placement: .automatic) {
                    if pendingCount > 0 {
                        Text("\(pendingCount) pendente\(pendingCount == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(item: $taskToEdit) { task in
                AddTaskView(taskToEdit: task)
            }
        }
    }

    private var emptyStateMessage: String {
        switch filter {
        case .all:
            return "Comece adicionando sua primeira tarefa."
        case .pending:
            return "Você não tem tarefas pendentes. Parabéns!"
        case .completed:
            return "Nenhuma tarefa concluída ainda."
        }
    }

    private func toggleTask(_ task: Item) {
        withAnimation {
            task.isCompleted.toggle()
            task.progress = task.isCompleted ? 100 : 0
            saveContext()
        }
    }

    @ViewBuilder
    private func taskRow(_ task: Item) -> some View {
        TaskRowView(task: task) {
            toggleTask(task)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            taskToEdit = task
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteTask(task)
            } label: {
                Label("Excluir", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                taskToEdit = task
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            Button(role: .destructive) {
                deleteTask(task)
            } label: {
                Label("Excluir", systemImage: "trash")
            }
        }
    }

    private func deleteTask(_ task: Item) {
        withAnimation {
            viewContext.delete(task)
            saveContext()
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredTasks[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Erro ao salvar: \(nsError), \(nsError.userInfo)")
        }
    }
}

#Preview {
    TaskListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
