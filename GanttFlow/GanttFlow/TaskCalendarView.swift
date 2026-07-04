//
//  TaskCalendarView.swift
//  teste
//

import SwiftUI
import CoreData

struct TaskCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ],
        animation: .default)
    private var tasks: FetchedResults<Item>

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonth = Date()
    @State private var showingAddTask = false
    @State private var taskToEdit: Item?

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "pt_BR")
        cal.firstWeekday = 1
        return cal
    }

    private var tasksWithDueDate: [Item] {
        tasks.filter { $0.dueDate != nil }
    }

    private var tasksByDay: [Date: [Item]] {
        Dictionary(grouping: tasksWithDueDate) { task in
            calendar.startOfDay(for: task.dueDate!)
        }
    }

    private var tasksForSelectedDay: [Item] {
        tasksByDay[selectedDate] ?? []
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MonthCalendarView(
                    displayedMonth: $displayedMonth,
                    selectedDate: $selectedDate,
                    tasksByDay: tasksByDay,
                    calendar: calendar
                )
                .padding(.horizontal)
                .padding(.top, 8)

                Divider()
                    .padding(.top, 12)

                selectedDaySection
            }
            .navigationTitle("Calendário")
            .toolbar {
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
                AddTaskView(initialDueDate: selectedDate)
            }
            .sheet(item: $taskToEdit) { task in
                AddTaskView(taskToEdit: task)
            }
        }
    }

    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "pt_BR"))))
                    .font(.headline)
                    .textCase(nil)

                Spacer()

                if !tasksForSelectedDay.isEmpty {
                    Text("\(tasksForSelectedDay.count) tarefa\(tasksForSelectedDay.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            if tasksForSelectedDay.isEmpty {
                ContentUnavailableView {
                    Label("Sem tarefas", systemImage: "calendar.badge.exclamationmark")
                } description: {
                    Text("Nenhuma tarefa com prazo neste dia.")
                } actions: {
                    Button("Adicionar tarefa") {
                        showingAddTask = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(tasksForSelectedDay) { task in
                        calendarTaskRow(task)
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
    }

    private func toggleTask(_ task: Item) {
        withAnimation {
            task.isCompleted.toggle()
            task.progress = task.isCompleted ? 100 : 0
            saveContext()
        }
    }

    @ViewBuilder
    private func calendarTaskRow(_ task: Item) -> some View {
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
            offsets.map { tasksForSelectedDay[$0] }.forEach(viewContext.delete)
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

// MARK: - Month Calendar

private struct MonthCalendarView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    let tasksByDay: [Date: [Item]]
    let calendar: Calendar

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "pt_BR")))
            .capitalized
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...]) + Array(symbols[..<start])
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }

        let daysCount = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 0
        let leadingEmpty = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)
        for day in 1...daysCount {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        return days
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthTitle)
                    .font(.title3.weight(.semibold))

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            tasks: tasksByDay[calendar.startOfDay(for: date)] ?? []
                        ) {
                            selectedDate = calendar.startOfDay(for: date)
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let tasks: [Item]
    let onTap: () -> Void

    private var dayNumber: String {
        date.formatted(.dateTime.day())
    }

    private var pendingCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.body.weight(isToday ? .bold : .regular))
                    .foregroundStyle(foregroundColor)

                if !tasks.isEmpty {
                    HStack(spacing: 3) {
                        if pendingCount > 0 {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 5, height: 5)
                        }
                        let completedCount = tasks.count - pendingCount
                        if completedCount > 0 {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 6)
                } else {
                    Spacer().frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background {
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                } else if isToday {
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        if isSelected { return .white }
        if isToday { return .accentColor }
        return .primary
    }
}

#Preview {
    TaskCalendarView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
