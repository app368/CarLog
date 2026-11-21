import Foundation
import SwiftData

// Задача: запись Maintenance Records — одна выполненная работа: какая, когда, на каком пробеге, где и за сколько
@Model
final class MaintenanceRecord {
    var service: MaintenanceItem?
    var center: ServiceCenter?
    var date: Date
    var odometer: Int?
    // Название центра текстом — так записи хранились до справочника сервисных центров.
    // При первом запуске новой версии текст переносится в справочник и очищается
    var serviceCenter: String = ""
    var cost: Double = 0
    var note: String = ""

    init(service: MaintenanceItem?, center: ServiceCenter?, date: Date, odometer: Int?, cost: Double, note: String) {
        self.service = service
        self.center = center
        self.date = date
        self.odometer = odometer
        self.cost = cost
        self.note = note
    }

    // Задача: название сервисного центра для списков и карточек
    var centerName: String {
        center?.name ?? serviceCenter
    }

    // Задача: один раз перенести названия центров из текста записей в справочник
    static func migrateCenterNames(in context: ModelContext) {
        let records = (try? context.fetch(FetchDescriptor<MaintenanceRecord>())) ?? []
        var centers = (try? context.fetch(FetchDescriptor<ServiceCenter>())) ?? []
        for record in records where record.center == nil && !record.serviceCenter.isEmpty {
            let name = record.serviceCenter.trimmingCharacters(in: .whitespaces)
            if let existing = centers.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                record.center = existing
            } else {
                let new = ServiceCenter(name: name)
                context.insert(new)
                centers.append(new)
                record.center = new
            }
            record.serviceCenter = ""
        }
    }
}
