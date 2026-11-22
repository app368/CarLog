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

    // При удалении компании платежи остаются, ссылка просто обнуляется
    @Relationship(deleteRule: .nullify, inverse: \InsuranceEntry.insurer)
    var entries: [InsuranceEntry] = []

    init(name: String) {
        self.name = name
    }
}
