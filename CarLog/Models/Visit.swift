import Foundation
import SwiftData

// Задача: визит в сервис — дата, сервисный центр, пробег, примечание;
// внутри строки визита (работы с ценами) и страницы документа из сервиса
@Model
final class Visit {
    var date: Date
    var odometer: Int?
    var note: String = ""
    var center: ServiceCenter?

    // При удалении визита удаляются и его строки, и фото документа — программа заранее спрашивает подтверждение
    @Relationship(deleteRule: .cascade, inverse: \VisitLine.visit)
    var lines: [VisitLine] = []

    @Relationship(deleteRule: .cascade, inverse: \DocumentPage.visit)
    var pages: [DocumentPage] = []

    init(date: Date, odometer: Int?, center: ServiceCenter?, note: String = "") {
        self.date = date
        self.odometer = odometer
        self.center = center
        self.note = note
    }

    // Задача: стоимость визита — сумма регламентных строк; ремонт и налог в неё не входят
    var total: Double {
        lines.reduce(0) { $0 + $1.price }
    }

    // Задача: строки в порядке документа
    var sortedLines: [VisitLine] {
        lines.sorted { $0.order < $1.order }
    }

    // Задача: страницы документа в порядке съёмки
    var sortedPages: [DocumentPage] {
        pages.sorted { $0.order < $1.order }
    }

    // Задача: название центра для списков и карточек
    var centerName: String {
        center?.name ?? ""
    }
}

// Задача: строка визита — одна строка документа из сервиса: название, цена и работы из справочника.
// Если в строке несколько работ (ремень ГРМ, помпа, приводной ремень), это группа с одной общей ценой
@Model
final class VisitLine {
    var visit: Visit?
    var name: String
    var price: Double = 0
    var order: Int = 0
    var services: [MaintenanceItem] = []

    init(name: String, price: Double, order: Int) {
        self.name = name
        self.price = price
        self.order = order
    }

    // Задача: работы строки одной подписью — «Timing belt · Water pump · Drive belt»,
    // в порядке стартового справочника; свои работы — после, по алфавиту
    var servicesText: String {
        let order = MaintenanceItem.defaults.map(\.name)
        let rank = { (item: MaintenanceItem) in (order.firstIndex(of: item.name) ?? order.count, item.name) }
        return services.sorted { rank($0) < rank($1) }.map(\.name).joined(separator: " · ")
    }
}

// Задача: страница документа из сервиса — снимок хранится отдельным файлом рядом с базой
@Model
final class DocumentPage {
    var visit: Visit?
    @Attribute(.externalStorage) var imageData: Data
    var order: Int = 0

    init(imageData: Data, order: Int) {
        self.imageData = imageData
        self.order = order
    }
}
