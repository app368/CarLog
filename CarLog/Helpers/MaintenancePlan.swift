import Foundation
import SwiftData

// Задача: показание одометра на дату — из заправки или записи о работе
struct OdometerReading {
    let date: Date
    let miles: Int
}

// Задача: пробег — текущий и средний в день; нужен, чтобы перевести норматив в милях в ориентировочную дату
enum Mileage {
    static func readings(fuel: [FuelEntry], records: [MaintenanceRecord]) -> [OdometerReading] {
        let fromFuel = fuel.compactMap { entry in entry.odometer.map { OdometerReading(date: entry.date, miles: $0) } }
        let fromRecords = records.compactMap { record in record.odometer.map { OdometerReading(date: record.date, miles: $0) } }
        return fromFuel + fromRecords
    }

    // Текущий пробег — самое большое показание одометра
    static func current(_ readings: [OdometerReading]) -> OdometerReading? {
        readings.max { $0.miles < $1.miles }
    }

    // Средний пробег в день — от самого раннего показания до самого позднего.
    // Если данных меньше чем за месяц, оценку не даём: она будет слишком неточной
    static func perDay(_ readings: [OdometerReading]) -> Double? {
        guard let first = readings.min(by: { $0.date < $1.date }),
              let last = readings.max(by: { $0.date < $1.date }) else { return nil }
        let days = last.date.timeIntervalSince(first.date) / 86_400
        let miles = Double(last.miles - first.miles)
        guard days >= 30, miles > 0 else { return nil }
        return miles / days
    }
}

// Задача: состояние работы в графике и его подпись
enum ScheduleStatus {
    case noRecord, noInterval, unknown, ok, soon, overdue

    var label: String {
        switch self {
        case .noRecord: "No record"
        case .noInterval, .unknown: "—"
        case .ok: "OK"
        case .soon: "Soon"
        case .overdue: "Overdue"
        }
    }
}

// Задача: одна строка графика — работа, последняя запись, следующий срок и статус
struct ScheduleLine: Identifiable {
    let item: MaintenanceItem
    let last: MaintenanceRecord?
    let nextDate: Date?
    let nextMiles: Int?
    let isEstimated: Bool
    let status: ScheduleStatus

    var id: PersistentIdentifier { item.persistentModelID }
}

// Задача: расчёт графика Maintenance Schedule по справочнику работ и записям
enum MaintenancePlan {
    // Задача: следующий срок работы.
    // Норматив в месяцах даёт точную дату, в милях — дату по среднему пробегу (со знаком «≈»).
    // Если заданы оба, берётся то, что наступит раньше
    static func line(for item: MaintenanceItem, currentMiles: Int?, milesPerDay: Double?,
                     today: Date = .now) -> ScheduleLine {
        guard let last = item.lastRecord else {
            return ScheduleLine(item: item, last: nil, nextDate: nil, nextMiles: nil, isEstimated: false, status: .noRecord)
        }
        guard item.intervalMiles != nil || item.intervalMonths != nil else {
            return ScheduleLine(item: item, last: last, nextDate: nil, nextMiles: nil, isEstimated: false, status: .noInterval)
        }

        var candidates: [(date: Date, estimated: Bool)] = []
        if let months = item.intervalMonths,
           let date = Calendar.current.date(byAdding: .month, value: months, to: last.date) {
            candidates.append((date, false))
        }
        var nextMiles: Int?
        if let miles = item.intervalMiles {
            nextMiles = last.odometer.map { $0 + miles }
            if let milesPerDay {
                candidates.append((last.date.addingTimeInterval(Double(miles) / milesPerDay * 86_400), true))
            }
        }
        let next = candidates.min { $0.date < $1.date }

        let milesLeft = zip2(nextMiles, currentMiles).map { $0 - $1 }
        let daysLeft = next.map { Calendar.current.dateComponents([.day], from: today, to: $0.date).day ?? 0 }
        let status: ScheduleStatus
        if milesLeft == nil && daysLeft == nil {
            status = .unknown
        } else if (milesLeft ?? 1) < 0 || (daysLeft ?? 1) < 0 {
            status = .overdue
        } else if (milesLeft ?? .max) <= 500 || (daysLeft ?? .max) <= 30 {
            status = .soon
        } else {
            status = .ok
        }
        return ScheduleLine(item: item, last: last, nextDate: next?.date, nextMiles: nextMiles,
                            isEstimated: next?.estimated ?? false, status: status)
    }

    // Задача: весь график с сортировкой — просроченные, затем по ближайшему сроку,
    // затем работы без срока, в конце — ни разу не записанные
    static func lines(for items: [MaintenanceItem], currentMiles: Int?, milesPerDay: Double?) -> [ScheduleLine] {
        items.map { line(for: $0, currentMiles: currentMiles, milesPerDay: milesPerDay) }
            .sorted { a, b in
                let ra = rank(a), rb = rank(b)
                if ra != rb { return ra < rb }
                let da = a.nextDate ?? .distantFuture, db = b.nextDate ?? .distantFuture
                if da != db { return da < db }
                return a.item.name.localizedStandardCompare(b.item.name) == .orderedAscending
            }
    }

    private static func rank(_ line: ScheduleLine) -> Int {
        switch line.status {
        case .overdue: 0
        case .soon, .ok: 1
        case .noInterval, .unknown: 2
        case .noRecord: 3
        }
    }

    private static func zip2(_ a: Int?, _ b: Int?) -> (Int, Int)? {
        guard let a, let b else { return nil }
        return (a, b)
    }
}
