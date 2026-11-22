import Foundation
import SwiftData

// Задача: справочник экстренных служб — название, телефон, адрес, сайт, email, примечание.
// Порядок ручной (911 сверху). role — метка стартовой записи: по ней руководство по ДТП
// находит нужный номер, даже если запись переименовали
@Model
final class EmergencyContact {
    var name: String
    var phone: String = ""
    var address: String = ""
    var website: String = ""
    var email: String = ""
    var notes: String = ""
    var order: Int = 0
    var role: String = ""

    init(name: String, order: Int) {
        self.name = name
        self.order = order
    }

    // Задача: стартовый набор для Портленда и Орегона. Номера сверены с portland.gov и oregon.gov 22 ноября 2026.
    // *677 (*OSP) в ссылке набрать нельзя — iOS не звонит по номерам со звёздочкой, поэтому он в примечании
    static let defaults: [(role: String, name: String, phone: String, website: String, notes: String)] = [
        ("emergency", "Emergency — police, fire, ambulance", "911", "",
         "Anyone hurt, a car blocking traffic, fire or leaking fuel, the other driver leaves or seems impaired."),
        ("police", "Portland Police — non-emergency", "503-823-3333",
         "https://www.portland.gov/911/when-call-non-emergency-503-823-3333",
         "Crash with no injuries in Portland or Multnomah County. Open 24/7. Crashes can't be reported online — call."),
        ("statePolice", "Oregon State Police — non-emergency", "800-442-0776",
         "https://www.oregon.gov/osp/Pages/contact.aspx",
         "Crash on a highway or freeway with no injuries. From a mobile phone you can also dial *677 (*OSP). Open 24/7."),
        ("dmv", "Oregon DMV — crash reports", "503-945-5098",
         "https://www.oregon.gov/odot/DMV/pages/driverid/accidentreport.aspx",
         "File a crash report within 72 hours if anyone is hurt, damage to your car is over $2,500, "
            + "or a car is towed and damage to any car is over $2,500. Needed even if the police made a report. "
            + "DMV general line: 503-945-5000.")
    ]

    // Задача: заполнить справочник стартовым набором, если он пуст
    static func seed(in context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<EmergencyContact>())) ?? 0
        guard existing == 0 else { return }
        for (order, item) in defaults.enumerated() {
            let contact = EmergencyContact(name: item.name, order: order)
            contact.phone = item.phone
            contact.website = item.website
            contact.notes = item.notes
            contact.role = item.role
            context.insert(contact)
        }
    }
}
