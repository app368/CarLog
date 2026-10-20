import Foundation
import SwiftData

// Задача: справочник марок бензина
@Model
final class FuelGrade {
    var name: String

    // При удалении марки записи остаются, ссылка просто обнуляется
    @Relationship(deleteRule: .nullify, inverse: \FuelEntry.grade)
    var entries: [FuelEntry] = []

    init(name: String) {
        self.name = name
    }

    // Задача: стартовый набор марок для США, заполняется один раз при первом запуске
    static let defaultNames = ["Regular 87", "Midgrade 89", "Premium 91", "Diesel"]
}
