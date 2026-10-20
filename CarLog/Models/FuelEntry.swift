import Foundation
import SwiftData

// Задача: запись о заправке — когда, сколько, почём и где
@Model
final class FuelEntry {
    var date: Date
    var odometer: Int?
    var gallons: Double
    var total: Double
    var station: Station?
    var grade: FuelGrade?

    init(date: Date, odometer: Int?, gallons: Double, total: Double, station: Station?, grade: FuelGrade?) {
        self.date = date
        self.odometer = odometer
        self.gallons = gallons
        self.total = total
        self.station = station
        self.grade = grade
    }

    // Задача: цена за галлон считается из фактических стоимости и объёма (вариант A)
    var pricePerGallon: Double {
        gallons > 0 ? total / gallons : 0
    }
}
