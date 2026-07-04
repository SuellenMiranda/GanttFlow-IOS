//
//  AddTaskView.swift
//  teste
//

import SwiftUI
import CoreData

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    var taskToEdit: Item?
    var initialDueDate: Date?

    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasStartDate = false
    @State private var startDate = Date()
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var progress: Double = 0
    @State private var isCompleted = false
    @State private var showDeleteConfirmation = false

    private var isEditing: Bool { taskToEdit != nil }

    private var durationDays: Int {
        guard hasStartDate, hasDueDate else { return 0 }
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: dueDate)
        return max(Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0, 0) + 1
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tarefa") {
                    TextField("Título", text: $title)
                    TextField("Notas (opcional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Prioridade") {
                    Picker("Prioridade", selection: $priority) {
                        ForEach(TaskPriority.allCases) { level in
                            Label(level.label, systemImage: level.icon)
                                .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("Definir data de início", isOn: $hasStartDate)
                    if hasStartDate {
                        DatePicker("Início", selection: $startDate, displayedComponents: [.date])
                    }

                    Toggle("Definir data de término", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Término", selection: $dueDate, displayedComponents: [.date])
                    }

                    if hasStartDate && hasDueDate {
                        LabeledContent("Duração") {
                            Text("\(durationDays) dia\(durationDays == 1 ? "" : "s")")
                                .foregroundStyle(.secondary)
                        }

                        if dueDate < startDate {
                            Label("A data de término deve ser igual ou posterior ao início.", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Cronograma (Gantt)")
                } footer: {
                    Text("Defina início e término para exibir a tarefa corretamente no gráfico de Gantt.")
                }

                Section("Progresso") {
                    Toggle("Concluída", isOn: $isCompleted)
                        .onChange(of: isCompleted) { _, completed in
                            if completed {
                                progress = 100
                            } else if progress >= 100 {
                                progress = 0
                            }
                        }

                    if !isCompleted {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Avanço")
                                Spacer()
                                Text("\(Int(progress))%")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: $progress, in: 0...100, step: 5)
                        }
                    }
                }

                if isEditing {
                    Section {
                        Button("Excluir tarefa", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                    }
                }
            }
            .confirmationDialog(
                "Excluir esta tarefa?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Excluir", role: .destructive, action: deleteTask)
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta ação não pode ser desfeita.")
            }
            .navigationTitle(isEditing ? "Editar Tarefa" : "Nova Tarefa")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Salvar" : "Adicionar") {
                        saveTask()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: setupForm)
        }
    }

    private var canSave: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespaces).isEmpty
        let validDates = !hasStartDate || !hasDueDate || dueDate >= startDate
        return hasTitle && validDates
    }

    private func setupForm() {
        if taskToEdit == nil, let date = initialDueDate {
            hasStartDate = true
            hasDueDate = true
            startDate = date
            dueDate = date
        }
        loadTask()
    }

    private func loadTask() {
        guard let task = taskToEdit else { return }
        title = task.title ?? ""
        notes = task.notes ?? ""
        priority = TaskPriority.from(task.priority)
        isCompleted = task.isCompleted
        progress = task.isCompleted ? 100 : Double(task.progress)

        if let start = task.startDate {
            hasStartDate = true
            startDate = start
        }
        if let due = task.dueDate {
            hasDueDate = true
            dueDate = due
        }
    }

    private func saveTask() {
        let task = taskToEdit ?? Item(context: viewContext)
        if taskToEdit == nil {
            task.createdAt = Date()
        }

        task.title = title.trimmingCharacters(in: .whitespaces)
        task.notes = notes.isEmpty ? nil : notes
        task.priority = priority.rawValue
        task.startDate = hasStartDate ? startDate : nil
        task.dueDate = hasDueDate ? dueDate : nil
        task.isCompleted = isCompleted
        task.progress = Int16(isCompleted ? 100 : Int(progress))

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Erro ao salvar: \(nsError), \(nsError.userInfo)")
        }
    }

    private func deleteTask() {
        guard let task = taskToEdit else { return }
        viewContext.delete(task)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Erro ao excluir: \(nsError), \(nsError.userInfo)")
        }
    }
}

#Preview {
    AddTaskView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
