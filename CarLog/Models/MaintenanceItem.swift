import Foundation
import SwiftData

// Задача: работа из справочника Maintenance Services — название, норматив по пробегу и/или времени, примечание.
// Когда работу делали, хранится не здесь, а в строках визитов
@Model
final class MaintenanceItem {
    var name: String
    var intervalMiles: Int?
    var intervalMonths: Int?
    var note: String = ""

    // Строки визитов, в которых есть эта работа. При удалении работы строки остаются, работа из них убирается
    @Relationship(deleteRule: .nullify, inverse: \VisitLine.services)
    var lines: [VisitLine] = []

    init(name: String, intervalMiles: Int?, intervalMonths: Int?, note: String = "") {
        self.name = name
        self.intervalMiles = intervalMiles
        self.intervalMonths = intervalMonths
        self.note = note
    }

    // Задача: стартовый набор из 16 работ для 2014 Acura MDX SH-AWD.
    // Источник нормативов — дилерская таблица Acura Maintenance Minder для MDX 2014–2015;
    // там интервалы даны диапазонами, здесь одно значение из диапазона — правится в карточке работы
    static let defaults: [(name: String, miles: Int?, months: Int?, note: String)] = [
        ("Oil & filter change", 5_000, 12, "Acura code A."),
        ("Tire rotation", 7_500, nil, "Acura code 1."),
        ("Engine air filter", 15_000, nil, "Acura code 2."),
        ("Cabin air filter", 15_000, nil, "Acura code 2."),
        ("Transmission fluid (ATF)", 30_000, nil, "Acura code 3, together with transfer case fluid."),
        ("Transfer case fluid", 30_000, nil, "Acura code 3, together with ATF. SH-AWD only."),
        ("Rear differential fluid", 15_000, nil, "Acura code 6. SH-AWD only."),
        ("Engine coolant", 75_000, nil, "Acura code 5. Also part of the timing belt service (code 4)."),
        ("Timing belt", 105_000, 84, "Acura code 4, together with tensioner, water pump, drive belt and spark plugs."),
        ("Timing belt tensioner", 105_000, 84, "Acura code 4, together with timing belt."),
        ("Water pump", 105_000, 84, "Acura code 4, together with timing belt."),
        ("Drive belt", 105_000, 84, "Acura code 4, together with timing belt."),
        ("Spark plugs", 105_000, nil, "Acura code 4, together with timing belt."),
        ("Brake fluid", nil, 36, "Every 3 years regardless of mileage."),
        ("Wheel alignment", 12_000, 12, ""),
        ("Valve adjustment", 150_000, nil, "Or when needed.")
    ]

    // Задача: визиты, в которых делали эту работу, новые сверху
    var visits: [Visit] {
        lines.compactMap(\.visit).sorted { $0.date > $1.date }
    }

    // Задача: последний визит с этой работой — от него график считает Last и Next
    var lastVisit: Visit? {
        lines.compactMap(\.visit).max { $0.date < $1.date }
    }

    // Задача: подпись норматива для списков — «5,000 mi or 12 mo»
    var intervalText: String {
        var parts: [String] = []
        if let intervalMiles { parts.append(intervalMiles.asMiles) }
        if let intervalMonths { parts.append("\(intervalMonths) mo") }
        return parts.isEmpty ? "No interval" : parts.joined(separator: " or ")
    }

    // Задача: короткая подпись норматива для таблицы дилера на вкладке My Car
    var intervalShort: String {
        intervalMiles == nil && intervalMonths == nil ? "—" : intervalText
    }
}
