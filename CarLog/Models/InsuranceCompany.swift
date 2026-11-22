import Foundation
import SwiftData

// Задача: справочник страховых компаний — номер полиса и контакты на случай ДТП:
// адрес, сайт, телефон, линия Claims (24/7), Customer Service, email и примечание
@Model
final class InsuranceCompany {
    var name: String
    var policyNumber: String = ""
    var address: String = ""
    var website: String = ""
    var phone: String = ""
    var claimsPhone: String = ""
    var servicePhone: String = ""
    var email: String = ""
    var notes: String = ""
    // Порядок строк раздела Contacts в карточке — названия полей; пусто — порядок по умолчанию
    var contactOrder: [String] = []

    // При удалении компании платежи остаются, ссылка просто обнуляется
    @Relationship(deleteRule: .nullify, inverse: \InsuranceEntry.insurer)
    var entries: [InsuranceEntry] = []

    init(name: String) {
        self.name = name
    }

    // Задача: строки раздела Contacts в сохранённом порядке; поля, которых нет в списке, — в конце
    var orderedContactFields: [InsuranceContactField] {
        let saved = contactOrder.compactMap(InsuranceContactField.init(rawValue:))
        return saved + InsuranceContactField.allCases.filter { !saved.contains($0) }
    }
}

// Задача: поля раздела Contacts карточки страховой компании — их порядок можно менять перетаскиванием
enum InsuranceContactField: String, CaseIterable {
    case address, website, phone, claims, service, email
}
