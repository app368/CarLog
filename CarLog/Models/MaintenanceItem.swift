import Foundation
import SwiftData

// Задача: норматив регламентной работы — интервал по пробегу и/или времени и когда делали в последний раз
@Model
final class MaintenanceItem {
    var name: String
    var intervalMiles: Int?
    var intervalMonths: Int?
    var lastDate: Date?
    var lastOdometer: Int?

    init(name: String, intervalMiles: Int?, intervalMonths: Int?) {
        self.name = name
        self.intervalMiles = intervalMiles
        self.intervalMonths = intervalMonths
    }

    // Задача: стартовый набор типовых нормативов, заполняется один раз при первом запуске.
    // Точные интервалы — в руководстве к машине, пользователь их правит
    static let defaults: [(name: String, miles: Int?, months: Int?)] = [
        ("Oil & filter change", 5_000, 6),
        ("Tire rotation", 7_500, nil),
        ("Engine air filter", 15_000, 12),
        ("Cabin air filter", 15_000, 12),
        ("Brake fluid", nil, 24)
    ]

    // Задача: сколько миль осталось до следующей работы (минус — просрочено)
    func milesLeft(currentOdometer: Int?) -> Int? {
        guard let intervalMiles, let lastOdometer, let currentOdometer else { return nil }
        return lastOdometer + intervalMiles - currentOdometer
    }

    // Задача: дата, к которой подходит срок по времени
    var dueDate: Date? {
        guard let intervalMonths, let lastDate else { return nil }
        return Calendar.current.date(byAdding: .month, value: intervalMonths, to: lastDate)
    }

    // Задача: состояние норматива для списка — не делали, в порядке, скоро, просрочено
    func status(currentOdometer: Int?, today: Date = .now) -> MaintenanceStatus {
        guard lastDate != nil || lastOdometer != nil else { return .noRecord }
        let miles = milesLeft(currentOdometer: currentOdometer)
        let days = dueDate.map { Calendar.current.dateComponents([.day], from: today, to: $0).day ?? 0 }
        if (miles ?? 1) < 0 || (days ?? 1) < 0 { return .overdue }
        if (miles ?? .max) <= 500 || (days ?? .max) <= 30 { return .soon }
        return .ok
    }

    // Задача: подпись «через сколько» — мили и/или дата
    func dueText(currentOdometer: Int?) -> String {
        var parts: [String] = []
        if let miles = milesLeft(currentOdometer: currentOdometer) {
            parts.append(miles >= 0 ? "in \(miles.asMiles)" : "\(abs(miles).asMiles) over")
        }
        if let dueDate {
            parts.append("by \(dueDate.formatted(date: .abbreviated, time: .omitted))")
        }
        return parts.joined(separator: " · ")
    }

    // Задача: подпись интервала — «Every 5,000 mi or 6 mo»
    var intervalText: String {
        var parts: [String] = []
        if let intervalMiles { parts.append(intervalMiles.asMiles) }
        if let intervalMonths { parts.append("\(intervalMonths) mo") }
        return parts.isEmpty ? "No interval" : "Every " + parts.joined(separator: " or ")
    }

    // Задача: отметить работу выполненной — если запись не старее последней отметки
    func markDone(date: Date, odometer: Int?) {
        if let lastDate, date < lastDate { return }
        lastDate = date
        lastOdometer = odometer
    }
}

// Задача: состояние норматива и его цвет в списке
enum MaintenanceStatus {
    case noRecord, ok, soon, overdue

    var label: String {
        switch self {
        case .noRecord: "No record"
        case .ok: "OK"
        case .soon: "Soon"
        case .overdue: "Overdue"
        }
    }
}
