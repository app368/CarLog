import Foundation
import SwiftData

// Задача: запись об оплате страховки и сроке действия полиса
@Model
final class InsuranceEntry {
    var datePaid: Date
    var validUntil: Date
    var amount: Double
    var company: String

    init(datePaid: Date, validUntil: Date, amount: Double, company: String) {
        self.datePaid = datePaid
        self.validUntil = validUntil
        self.amount = amount
        self.company = company
    }

    // Задача: полис истёк — показываем это в списке
    var isExpired: Bool {
        validUntil < Calendar.current.startOfDay(for: .now)
    }
}
