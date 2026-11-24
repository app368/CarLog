import Foundation
import SwiftData

// Задача: продление регистрации машины — кто выдал (Oregon DMV), сумма, дата оплаты, срок действия,
// примечание и документы этого периода (регистрационная карточка)
@Model
final class RegistrationEntry {
    var issuedBy: String = ""
    var datePaid: Date
    var validUntil: Date
    // Сумма необязательна: 0 — не введена, в списке и карточке её тогда не видно
    var amount: Double = 0
    var notes: String = ""

    // При удалении записи удаляются и её документы — программа заранее спрашивает подтверждение
    @Relationship(deleteRule: .cascade, inverse: \DocumentPage.registration)
    var pages: [DocumentPage] = []

    init(issuedBy: String, datePaid: Date, validUntil: Date, amount: Double) {
        self.issuedBy = issuedBy
        self.datePaid = datePaid
        self.validUntil = validUntil
        self.amount = amount
    }

    // Задача: документы в порядке добавления
    var sortedPages: [DocumentPage] {
        pages.sorted { $0.order < $1.order }
    }

    // Задача: регистрация истекла — показываем это в списке
    var isExpired: Bool {
        validUntil < Calendar.current.startOfDay(for: .now)
    }
}
