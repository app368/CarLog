import Foundation
import SwiftData

// Задача: справочник заправок — название и адрес вводятся вручную
@Model
final class Station {
    var name: String
    var address: String

    // При удалении заправки записи остаются, ссылка просто обнуляется
    @Relationship(deleteRule: .nullify, inverse: \FuelEntry.station)
    var entries: [FuelEntry] = []

    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}
