import Foundation
import SwiftData

// Задача: запись о регламентных работах — что сделано, когда, на каком пробеге и за сколько
@Model
final class ServiceEntry {
    var date: Date
    var odometer: Int?
    var amount: Double
    var work: String

    init(date: Date, odometer: Int?, amount: Double, work: String) {
        self.date = date
        self.odometer = odometer
        self.amount = amount
        self.work = work
    }
}
