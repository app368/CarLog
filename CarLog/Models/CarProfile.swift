import Foundation
import SwiftData

// Задача: данные автомобиля — производитель, марка, модель, год и другие параметры (одна запись на приложение).
// Термины как в базе VIN-кодов NHTSA: Manufacturer — Honda, Make — Acura, Model — MDX
@Model
final class CarProfile {
    var manufacturer: String = ""
    var make: String = ""
    var model: String = ""
    var year: Int?
    var vin: String = ""
    var plate: String = ""

    init() {}
}
