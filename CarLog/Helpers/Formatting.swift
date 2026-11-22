import Foundation

// Задача: единое форматирование денег, галлонов и пробега во всём приложении
extension Double {
    var asMoney: String {
        formatted(.currency(code: "USD"))
    }

    // Цена за галлон — три знака, как на табло заправки
    var asPricePerGallon: String {
        formatted(.currency(code: "USD").precision(.fractionLength(3)))
    }

    var asGallons: String {
        formatted(.number.precision(.fractionLength(3))) + " gal"
    }
}

extension Int {
    var asMiles: String {
        formatted() + " mi"
    }
}

extension Date {
    // Задача: дата для имени файла — «2025-10-30» по местному времени (стандартный ISO-формат берёт UTC)
    var fileDay: String {
        formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
    }
}

// Задача: разбор чисел из текстовых полей формы (точка или запятая)
enum NumberInput {
    static func double(_ text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }

    static func int(_ text: String) -> Int? {
        Int(text.filter(\.isNumber))
    }

    // Задача: показать сохранённое число в поле формы без лишних нулей
    static func text(_ value: Double?) -> String {
        guard let value else { return "" }
        return value.formatted(.number.grouping(.never).precision(.fractionLength(0...3)).locale(Locale(identifier: "en_US")))
    }
}
