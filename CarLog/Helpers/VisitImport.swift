import Foundation
import SwiftData

// Задача: файл визита — готовится на компьютере по документу из сервиса и импортируется на телефоне.
// Дата — строкой «2025-10-30», работы — названиями из справочника Maintenance Services.
// Лишние поля (исходный текст строки, ремонт, итоги документа) приложение пропускает — они для разбора
struct VisitFile: Codable, Identifiable {
    var date: String
    var center: String?
    var odometer: Int?
    var note: String?
    var lines: [Line]

    struct Line: Codable {
        var name: String
        var price: Double
        var services: [String]
    }

    var id: String { date + (center ?? "") }

    // Задача: дата визита — полночь этого дня по местному времени
    var day: Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }

    var total: Double {
        lines.reduce(0) { $0 + $1.price }
    }

    var centerName: String {
        center?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    // Задача: прочитать файл и сразу проверить дату
    static func decode(_ data: Data) throws -> VisitFile {
        let file = try JSONDecoder().decode(VisitFile.self, from: data)
        guard file.day != nil else { throw VisitFileError.badDate(file.date) }
        return file
    }
}

enum VisitFileError: LocalizedError {
    case badDate(String)

    var errorDescription: String? {
        switch self {
        case .badDate(let text): "The date “\(text)” should look like 2025-10-30."
        }
    }
}

// Задача: перенос файла визита в приложение.
// Визит с той же датой и тем же центром (или без центра) обновляется: шапка и строки заменяются, фото остаются.
// Иначе создаётся новый визит. Центра нет в справочнике — добавляется; работы ищутся по названию
enum VisitImporter {
    // Задача: найти уже введённый визит, который этот файл дополняет
    static func existingVisit(for file: VisitFile, in visits: [Visit]) -> Visit? {
        guard let day = file.day else { return nil }
        let sameDay = visits.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
        return sameDay.first { sameName($0.centerName, file.centerName) } ?? sameDay.first { $0.center == nil }
    }

    // Задача: центр из справочника по названию
    static func center(named name: String, in centers: [ServiceCenter]) -> ServiceCenter? {
        centers.first { sameName($0.name, name) }
    }

    // Задача: работа из справочника по названию
    static func service(named name: String, in items: [MaintenanceItem]) -> MaintenanceItem? {
        items.first { sameName($0.name, name) }
    }

    // Задача: создать или обновить визит по файлу и вернуть его
    static func apply(_ file: VisitFile, in context: ModelContext) throws -> Visit {
        let visits = try context.fetch(FetchDescriptor<Visit>())
        let centers = try context.fetch(FetchDescriptor<ServiceCenter>())
        let items = try context.fetch(FetchDescriptor<MaintenanceItem>())

        var center: ServiceCenter?
        if !file.centerName.isEmpty {
            center = Self.center(named: file.centerName, in: centers)
            if center == nil {
                let new = ServiceCenter(name: file.centerName)
                context.insert(new)
                center = new
            }
        }

        let visit: Visit
        if let existing = existingVisit(for: file, in: visits) {
            visit = existing
        } else {
            visit = Visit(date: file.day ?? .now, odometer: nil, center: nil)
            context.insert(visit)
        }
        visit.center = center ?? visit.center
        visit.odometer = file.odometer ?? visit.odometer
        if let note = file.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            visit.note = note
        }

        for line in visit.lines {
            context.delete(line)
        }
        visit.lines = []
        for (order, dto) in file.lines.enumerated() {
            let line = VisitLine(name: dto.name, price: dto.price, order: order)
            context.insert(line)
            line.visit = visit
            line.services = dto.services.compactMap { service(named: $0, in: items) }
        }
        try context.save()
        return visit
    }

    private static func sameName(_ a: String, _ b: String) -> Bool {
        a.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(b.trimmingCharacters(in: .whitespaces)) == .orderedSame
    }
}
