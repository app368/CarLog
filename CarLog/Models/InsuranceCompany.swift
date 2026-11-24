import Foundation
import SwiftData

// Задача: справочник страховых компаний — номер полиса и контакты на случай ДТП:
// адрес, сайт, телефон, линия Claims (24/7), Customer Service, email и примечание
@Model
final class InsuranceCompany {
    var name: String
    // Номер полиса раньше хранился здесь; теперь он в оплате, а поле осталось только для старых данных
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

    // Задача: номер полиса для карточки компании — из её последней оплаты; правится только в оплате
    var currentPolicyNumber: String {
        entries.max { $0.datePaid < $1.datePaid }?.policyNumber ?? ""
    }

    // Задача: текущая страховая — компания последнего платежа, а без платежей — единственная в справочнике.
    // Нужна строке Insurance claims и руководству по ДТП
    static func current(payments: [InsuranceEntry], companies: [InsuranceCompany]) -> InsuranceCompany? {
        payments.max { $0.datePaid < $1.datePaid }?.insurer ?? (companies.count == 1 ? companies.first : nil)
    }
}
