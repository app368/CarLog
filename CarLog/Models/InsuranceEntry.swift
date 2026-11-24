import Foundation
import SwiftData

// Задача: запись об оплате страховки — срок действия полиса, номер полиса, примечание
// и документы этого периода (страховая карточка, полис); компания — из справочника
@Model
final class InsuranceEntry {
    var datePaid: Date
    var validUntil: Date
    // Сумма необязательна: 0 — не введена, в списке и карточке её тогда не видно
    var amount: Double
    var insurer: InsuranceCompany?
    // Номер полиса — у каждой оплаты свой: при смене компании он меняется, при продлении обычно тот же
    var policyNumber: String = ""
    var notes: String = ""
    // Название компании текстом — так платежи хранились до справочника страховых компаний.
    // При первом запуске новой версии текст переносится в справочник и очищается
    var company: String

    // При удалении оплаты удаляются и её документы — программа заранее спрашивает подтверждение
    @Relationship(deleteRule: .cascade, inverse: \DocumentPage.insurance)
    var pages: [DocumentPage] = []

    init(datePaid: Date, validUntil: Date, amount: Double, company: String) {
        self.datePaid = datePaid
        self.validUntil = validUntil
        self.amount = amount
        self.company = company
    }

    // Задача: документы в порядке добавления
    var sortedPages: [DocumentPage] {
        pages.sorted { $0.order < $1.order }
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
}
