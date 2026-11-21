import Foundation
import SwiftData

// Задача: справочник заправок — название, адрес и примечание вводятся вручную
@Model
final class Station {
    var name: String
    var address: String
    var notes: String = ""

    // При удалении заправки записи остаются, ссылка просто обнуляется
    @Relationship(deleteRule: .nullify, inverse: \FuelEntry.station)
    var entries: [FuelEntry] = []

    init(name: String, address: String, notes: String = "") {
        self.name = name
        self.address = address
        self.notes = notes
    }
}
