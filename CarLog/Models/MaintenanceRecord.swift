import Foundation
import SwiftData

// Задача: запись Maintenance Records — одна выполненная работа: какая, когда, на каком пробеге, где и за сколько
@Model
final class MaintenanceRecord {
    var service: MaintenanceItem?
    var date: Date
    var odometer: Int?
    var serviceCenter: String = ""
    var cost: Double = 0
    var note: String = ""

    init(service: MaintenanceItem?, date: Date, odometer: Int?, serviceCenter: String, cost: Double, note: String) {
        self.service = service
        self.date = date
        self.odometer = odometer
        self.serviceCenter = serviceCenter
        self.cost = cost
        self.note = note
    }
}
