import Foundation
import SwiftData

// Задача: файл визита — готовится на компьютере по документу из сервиса и импортируется на телефоне.
// Дата — строкой «2025-10-30», работы — названиями из справочника Maintenance Services,
// центр — названием из справочника Service centers и, по желанию, его адресом и контактами из шапки документа.
// Лишние поля (исходный текст строки, ремонт, итоги документа) приложение пропускает — они для разбора
struct VisitFile: Codable, Identifiable {
    var date: String
    var center: String?
    var centerDetails: CenterDetails?
    var odometer: Int?
    var note: String?
    var lines: [Line]

    struct Line: Codable {
        var name: String
        var price: Double
        var services: [String]
    }

    // Адрес и контакты центра из шапки документа — все поля необязательны
    struct CenterDetails: Codable {
        var address: String?
        var phone: String?
        var website: String?
        var email: String?
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
// Визит ищется только по дате: если он уже введён, строки и пробег заменяются, а фото и своё примечание остаются.
// Иначе создаётся новый визит. Центр из файла главнее центра визита — где делали работу, знает документ
// (форма нового визита подставляет центр прошлого визита, и он мог оказаться чужим).
// Центр ищется в справочнике по названию: нет — добавляется с адресом и контактами из файла,
// есть — у него заполняются только пустые поля. Работы ищутся по названию
enum VisitImporter {
    // Задача: найти уже введённый визит, который этот файл дополняет, — визит в тот же день.
    // Если таких несколько, сначала тот, у которого центр совпадает с файлом
    static func existingVisit(for file: VisitFile, in visits: [Visit]) -> Visit? {
        guard let day = file.day else { return nil }
        let sameDay = visits.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
        return sameDay.first { sameName($0.centerName, file.centerName) } ?? sameDay.first
    }

    // Задача: центр из справочника по названию
    static func center(named name: String, in centers: [ServiceCenter]) -> ServiceCenter? {
        centers.first { sameName($0.name, name) }
    }

    // Задача: центр для визита из файла — найти в справочнике или добавить, и дописать адрес и контакты
    private static func serviceCenter(for file: VisitFile, in centers: [ServiceCenter],
                                      context: ModelContext) -> ServiceCenter {
        let center: ServiceCenter
        if let found = Self.center(named: file.centerName, in: centers) {
            center = found
        } else {
            center = ServiceCenter(name: file.centerName)
            context.insert(center)
        }
        fillEmptyFields(of: center, from: file.centerDetails)
        return center
    }

    // Задача: дописать в центр адрес и контакты из файла — только в пустые поля, правки в справочнике не трогаем
    private static func fillEmptyFields(of center: ServiceCenter, from details: VisitFile.CenterDetails?) {
        guard let details else { return }
        func fill(_ value: inout String, with new: String?) {
            let new = new?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if value.trimmingCharacters(in: .whitespaces).isEmpty, !new.isEmpty { value = new }
        }
        fill(&center.address, with: details.address)
        fill(&center.phone, with: details.phone)
        fill(&center.website, with: details.website)
        fill(&center.email, with: details.email)
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
        if !file.centerName.isEmpty {
            visit.center = serviceCenter(for: file, in: centers, context: context)
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
