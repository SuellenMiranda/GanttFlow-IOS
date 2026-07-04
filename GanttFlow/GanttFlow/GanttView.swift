//
//  GanttView.swift
//  teste
//

import SwiftUI
import CoreData

struct GanttView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Item.startDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ],
        animation: .default)
    private var tasks: FetchedResults<Item>

    @State private var taskToEdit: Item?
    @State private var taskToDelete: Item?
    @State private var showDeleteConfirmation = false

    private let labelWidth: CGFloat = 140
    private let rowHeight: CGFloat = 48
    private let dayWidth: CGFloat = 28

    private var calendar: Calendar { Calendar.current }

    private var timelineStart: Date {
        guard !tasks.isEmpty else {
            return calendar.startOfDay(for: Date())
        }
        let earliest = tasks.map(\.ganttStart).min()!
        return calendar.date(byAdding: .day, value: -2, to: earliest) ?? earliest
    }

    private var timelineEnd: Date {
        guard !tasks.isEmpty else {
            return calendar.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        }
        let latest = tasks.map(\.ganttEnd).max()!
        return calendar.date(byAdding: .day, value: 2, to: latest) ?? latest
    }

    private var dayCount: Int {
        max(calendar.dateComponents([.day], from: timelineStart, to: timelineEnd).day ?? 0, 1) + 1
    }

    private var timelineWidth: CGFloat {
        CGFloat(dayCount) * dayWidth
    }

    private var days: [Date] {
        (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: timelineStart)
        }
    }

    private var tasksWithoutSchedule: [Item] {
        tasks.filter { !$0.hasExplicitSchedule }
    }

    var body: some View {
        NavigationStack {
            Group {
                if tasks.isEmpty {
                    ContentUnavailableView {
                        Label("Nenhuma tarefa", systemImage: "chart.bar.xaxis")
                    } description: {
                        Text("Adicione tarefas na aba Tarefas para visualizá-las no Gantt.")
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if !tasksWithoutSchedule.isEmpty {
                                scheduleWarning
                            }

                            legend

                            chartScrollView
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Gantt")
            .sheet(item: $taskToEdit) { task in
                AddTaskView(taskToEdit: task)
            }
            .confirmationDialog(
                "Excluir esta tarefa?",
                isPresented: $showDeleteConfirmation,
                presenting: taskToDelete
            ) { task in
                Button("Excluir", role: .destructive) {
                    deleteTask(task)
                }
                Button("Cancelar", role: .cancel) {
                    taskToDelete = nil
                }
            } message: { _ in
                Text("Esta ação não pode ser desfeita.")
            }
        }
    }

    private func deleteTask(_ task: Item) {
        withAnimation {
            viewContext.delete(task)
            taskToDelete = nil
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Erro ao excluir: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private var scheduleWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Cronograma incompleto", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)

            Text("\(tasksWithoutSchedule.count) tarefa(s) sem datas de início e término definidas. Toque para completar o cronograma.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(tasksWithoutSchedule.prefix(3)) { task in
                Button {
                    taskToEdit = task
                } label: {
                    HStack {
                        Text(task.title ?? "Sem título")
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: TaskPriority.high.color, label: "Alta")
            legendItem(color: TaskPriority.medium.color, label: "Média")
            legendItem(color: TaskPriority.low.color, label: "Baixa")
            legendItem(color: .green.opacity(0.6), label: "Progresso")
        }
        .font(.caption2)
        .padding(.horizontal)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    private var chartScrollView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                timelineHeader

                ForEach(tasks) { task in
                    ganttRow(for: task)
                }
            }
            .padding(.horizontal)
        }
    }

    private var timelineHeader: some View {
        HStack(spacing: 0) {
            Text("Tarefa")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: labelWidth, height: 36, alignment: .leading)
                .padding(.leading, 4)

            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    VStack(spacing: 2) {
                        Text(day.formatted(.dateTime.day()))
                            .font(.caption2.weight(calendar.isDateInToday(day) ? .bold : .regular))
                        Text(day.formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: "pt_BR"))))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: dayWidth, height: 36)
                    .background(calendar.isDateInToday(day) ? Color.accentColor.opacity(0.15) : Color.clear)
                }
            }
            .frame(width: timelineWidth)
        }
        .background(.quaternary.opacity(0.3))
    }

    private func ganttRow(for task: Item) -> some View {
        HStack(spacing: 0) {
            Button {
                taskToEdit = task
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title ?? "Sem título")
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)

                    Text("\(task.ganttDurationDays)d · \(Int(task.ganttProgress * 100))%")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(width: labelWidth, height: rowHeight, alignment: .leading)
                .padding(.leading, 4)
            }
            .buttonStyle(.plain)

            ZStack(alignment: .leading) {
                gridBackground

                GanttBarView(
                    task: task,
                    timelineStart: timelineStart,
                    dayWidth: dayWidth,
                    calendar: calendar
                )
            }
            .frame(width: timelineWidth, height: rowHeight)
        }
        .background(Color.primary.opacity(0.02))
        .overlay(alignment: .bottom) {
            Divider()
        }
        .contextMenu {
            Button {
                taskToEdit = task
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            Button(role: .destructive) {
                taskToDelete = task
                showDeleteConfirmation = true
            } label: {
                Label("Excluir", systemImage: "trash")
            }
        }
    }

    private var gridBackground: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                Rectangle()
                    .fill(calendar.isDateInToday(day) ? Color.accentColor.opacity(0.06) : Color.clear)
                    .frame(width: dayWidth)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(Color.primary.opacity(0.06))
                            .frame(width: 0.5)
                    }
            }
        }
    }
}

// MARK: - Gantt Bar

private struct GanttBarView: View {
    let task: Item
    let timelineStart: Date
    let dayWidth: CGFloat
    let calendar: Calendar

    private var priority: TaskPriority {
        TaskPriority.from(task.priority)
    }

    private var startOffset: CGFloat {
        let days = calendar.dateComponents([.day], from: timelineStart, to: task.ganttStart).day ?? 0
        return CGFloat(max(days, 0)) * dayWidth
    }

    private var barWidth: CGFloat {
        max(CGFloat(task.ganttDurationDays) * dayWidth - 4, dayWidth * 0.6)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(priority.color.opacity(task.isCompleted ? 0.35 : 0.85))
                .frame(width: barWidth, height: 22)
                .overlay {
                    if !task.hasExplicitSchedule {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(priority.color)
                    }
                }

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.green.opacity(0.7))
                .frame(width: barWidth * task.ganttProgress, height: 22)

            HStack(spacing: 4) {
                Text(task.title ?? "")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
            .padding(.horizontal, 6)
            .frame(width: barWidth, alignment: .leading)
        }
        .offset(x: startOffset + 2)
        .opacity(task.isCompleted ? 0.7 : 1)
    }
}

#Preview {
    GanttView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
