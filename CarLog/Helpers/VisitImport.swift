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
// Визит ищется только по дате: если он уже введён, строки и пробег заменяются, а центр, фото и своё примечание остаются.
// Иначе создаётся новый визит. Центр из файла нужен, только если у визита центра нет:
// не найден в справочнике — добавляется. Работы ищутся по названию
enum VisitImporter {
    // Задача: найти уже введённый визит, который этот файл дополняет, — визит в тот же день.
    // Если таких несколько, сначала тот, у которого центр совпадает с файлом
    static func existingVisit(for file: VisitFile, in visits: [Visit]) -> Visit? {
        guard let day = file.day else { return nil }
        let sameDay = visits.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
        return sameDay.first { sameName($0.centerName, file.centerName) } ?? sameDay.first
    }

    // Задача: нужен ли центр из файла — да, если визит новый или у введённого визита центра нет
    static func usesFileCenter(_ file: VisitFile, existing: Visit?) -> Bool {
        !file.centerName.isEmpty && existing?.center == nil
    }

    // Задача: центр из справочника по названию
    static func center(named name: String, in centers: [ServiceCenter]) -> ServiceCenter? {
        centers.first { sameName($0.name, name) }
    }

    // Задача: работа из справочника по названию
    static func service(named name: String, in items: [MaintenanceItem]) -> MaintenanceItem? {
        items.first { sameName($0.name, name) }
    }

    // Задача: создать или обновить визит по файлу и вернуть его.
    // target — визит, из карточки которого запущен импорт: файл записывается прямо в него
    static func apply(_ file: VisitFile, to target: Visit? = nil, in context: ModelContext) throws -> Visit {
        let visits = try context.fetch(FetchDescriptor<Visit>())
        let centers = try context.fetch(FetchDescriptor<ServiceCenter>())
        let items = try context.fetch(FetchDescriptor<MaintenanceItem>())

        let existing = target ?? existingVisit(for: file, in: visits)
        let visit: Visit
        if let existing {
            visit = existing
        } else {
            visit = Visit(date: file.day ?? .now, odometer: nil, center: nil)
            context.insert(visit)
        }
        if usesFileCenter(file, existing: existing) {
            if let found = Self.center(named: file.centerName, in: centers) {
                visit.center = found
            } else {
                let new = ServiceCenter(name: file.centerName)
                context.insert(new)
                visit.center = new
            }
        }
        visit.odometer = file.odometer ?? visit.odometer
        // Примечание из файла (ремонт и прочее вне Total) — только если своего ещё нет, чтобы не стереть правки
        if let note = file.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty,
           visit.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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

    // Задача: что в файле не сошлось — работы, которых нет в справочнике,
    // и другая дата при импорте в открытый визит. Пусто — всё в порядке, сообщение не нужно
    static func problems(for file: VisitFile, target: Visit?, in context: ModelContext) throws -> [String] {
        let items = try context.fetch(FetchDescriptor<MaintenanceItem>())
        var result: [String] = []
        let missing = Set(file.lines.flatMap(\.services).filter { service(named: $0, in: items) == nil })
        if !missing.isEmpty {
            result.append("Not found in Services: \(missing.sorted().joined(separator: ", ")). "
                + "These lines were imported without them.")
        }
        if let target, let day = file.day, !Calendar.current.isDate(target.date, inSameDayAs: day) {
            result.append("The file is for \(day.formatted(date: .abbreviated, time: .omitted)), "
                + "this visit is on \(target.date.formatted(date: .abbreviated, time: .omitted)). The visit date was kept.")
        }
        return result
    }

    private static func sameName(_ a: String, _ b: String) -> Bool {
        a.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(b.trimmingCharacters(in: .whitespaces)) == .orderedSame
    }
}
