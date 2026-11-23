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

// Задача: номер телефона США в привычном виде — (503) 823-3333, 1 (800) 442-0776, 911.
// Номера со звёздочкой, буквами или чужим кодом страны (*677, +44…) остаются как введены
enum PhoneFormat {
    // typing: true — формат по мере ввода (неполный номер тоже раскладывается по группам);
    // false — для показа: формат только у полного номера (3, 7 или 10 цифр), остальное как есть
    static func format(_ text: String, typing: Bool = false) -> String {
        let allowed = Set("0123456789 ()-.+")
        guard !text.isEmpty, text.allSatisfy({ allowed.contains($0) }) else { return text }
        var digits = text.filter(\.isNumber)
        var prefix = ""
        if text.hasPrefix("+") {
            guard digits.first == "1" else { return text }
            prefix = "+1"
            digits.removeFirst()
        } else if digits.first == "1", digits.count > 1 {
            // У кодов зон США первая цифра не 1 — значит, это междугородний префикс
            prefix = "1"
            digits.removeFirst()
        }
        if !prefix.isEmpty && digits.isEmpty { return prefix }
        let lead = prefix.isEmpty ? "" : prefix + " "
        if typing {
            guard digits.count <= 10 else { return text }
            return lead + groups(digits)
        }
        switch digits.count {
        case 10: return lead + groups(digits)
        case 7 where prefix.isEmpty: return "\(digits.prefix(3))-\(digits.dropFirst(3))"
        case 3 where prefix.isEmpty: return digits
        default: return text
        }
    }

    // Раскладка по группам без хвостовых разделителей: 503 → (503) 8 → (503) 823-3
    private static func groups(_ digits: String) -> String {
        let area = digits.prefix(3), middle = digits.dropFirst(3).prefix(3), last = digits.dropFirst(6)
        switch digits.count {
        case 0...3: return String(area)
        case 4...6: return "(\(area)) \(middle)"
        default: return "(\(area)) \(middle)-\(last)"
        }
    }
}
