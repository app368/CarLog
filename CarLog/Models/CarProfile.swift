import Foundation
import SwiftData

// Задача: данные автомобиля — марка, модель, год и другие параметры (одна запись на приложение)
@Model
final class CarProfile {
    var make: String = ""
    var model: String = ""
    var year: Int?
    var vin: String = ""
    var plate: String = ""

    init() {}
}
