import Foundation
import SwiftData

// Задача: запись об оплате страховки и сроке действия полиса; компания — из справочника
@Model
final class InsuranceEntry {
    var datePaid: Date
    var validUntil: Date
    var amount: Double
    var insurer: InsuranceCompany?
    // Название компании текстом — так платежи хранились до справочника страховых компаний.
    // При первом запуске новой версии текст переносится в справочник и очищается
    var company: String

    init(datePaid: Date, validUntil: Date, amount: Double, company: String) {
        self.datePaid = datePaid
        self.validUntil = validUntil
        self.amount = amount
        self.company = company
    }

    // Задача: название компании для списков и карточек
    var companyName: String {
        insurer?.name ?? company
    }

    // Задача: один раз перенести названия компаний из текста платежей в справочник
    static func migrateCompanyNames(in context: ModelContext) {
        let entries = (try? context.fetch(FetchDescriptor<InsuranceEntry>())) ?? []
        var companies = (try? context.fetch(FetchDescriptor<InsuranceCompany>())) ?? []
        for entry in entries where entry.insurer == nil && !entry.company.isEmpty {
            let name = entry.company.trimmingCharacters(in: .whitespaces)
            if let existing = companies.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                entry.insurer = existing
            } else {
                let new = InsuranceCompany(name: name)
                context.insert(new)
                companies.append(new)
                entry.insurer = new
            }
            entry.company = ""
        }
    }

    // Задача: полис истёк — показываем это в списке
    var isExpired: Bool {
        validUntil < Calendar.current.startOfDay(for: .now)
    }
}
