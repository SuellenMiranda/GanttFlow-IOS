//
//  Item+Gantt.swift
//  teste
//

import Foundation

extension Item {
    var ganttStart: Date {
        if let startDate {
            return Calendar.current.startOfDay(for: startDate)
        }
        if let createdAt {
            return Calendar.current.startOfDay(for: createdAt)
        }
        return Calendar.current.startOfDay(for: Date())
    }

    var ganttEnd: Date {
        let start = ganttStart
        if let dueDate {
            let end = Calendar.current.startOfDay(for: dueDate)
            return end >= start ? end : start
        }
        return Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
    }

    var ganttProgress: Double {
        if isCompleted { return 1.0 }
        return min(max(Double(progress) / 100.0, 0), 1.0)
    }

    var ganttDurationDays: Int {
        max(Calendar.current.dateComponents([.day], from: ganttStart, to: ganttEnd).day ?? 0, 0) + 1
    }

    var hasExplicitSchedule: Bool {
        startDate != nil && dueDate != nil
    }
}
