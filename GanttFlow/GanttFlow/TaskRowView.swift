//
//  TaskRowView.swift
//  teste
//

import SwiftUI

struct TaskRowView: View {
    @ObservedObject var task: Item
    var onToggle: () -> Void

    private var priority: TaskPriority {
        TaskPriority.from(task.priority)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Sem título")
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    Label(priority.label, systemImage: priority.icon)
                        .font(.caption)
                        .foregroundStyle(priority.color)

                    if task.startDate != nil || task.dueDate != nil {
                        Label(scheduleLabel, systemImage: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundStyle(isOverdue ? .red : .secondary)
                    }

                    if !task.isCompleted && task.progress > 0 {
                        Text("\(task.progress)%")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var scheduleLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")

        switch (task.startDate, task.dueDate) {
        case let (start?, end?):
            return "\(formatter.string(from: start)) → \(formatter.string(from: end))"
        case (nil, let end?):
            return "até \(formatter.string(from: end))"
        case (let start?, nil):
            return "de \(formatter.string(from: start))"
        default:
            return ""
        }
    }

    private var isOverdue: Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else { return false }
        return dueDate < Date()
    }
}
