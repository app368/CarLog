import Foundation

// Задача: дилерская таблица Acura Maintenance Minder для 2014–2015 MDX — справочник для экрана регламента.
// appItem — название норматива в приложении, если такой есть (у сервиса B его нет)
struct MaintenanceGuideRow: Identifiable {
    let code: String
    let work: String
    let appItem: String?
    let acura: String

    var id: String { work }
}

enum MaintenanceGuide {
    static let title = "2014–2015 Acura MDX"
    static let source = "Acura dealer Maintenance Minder chart for 2014–2015 MDX. Acura intervals are estimates — if Maintenance Minder in the car asks earlier, follow it."

    static let rows: [MaintenanceGuideRow] = [
        .init(code: "A", work: "Oil & filter change", appItem: "Oil & filter change", acura: "4,000–9,000 mi or 12 mo"),
        .init(code: "B", work: "Oil service and inspection", appItem: nil, acura: "7,500–20,000 mi"),
        .init(code: "1", work: "Tire rotation", appItem: "Tire rotation", acura: "4,000–9,000 mi"),
        .init(code: "2", work: "Engine air filter", appItem: "Engine air filter", acura: "15,000–30,000 mi"),
        .init(code: "2", work: "Cabin air filter", appItem: "Cabin air filter", acura: "15,000–30,000 mi"),
        .init(code: "3", work: "Transmission & transfer fluid", appItem: "Transmission & transfer fluid", acura: "20,000–40,000 mi"),
        .init(code: "4", work: "Timing belt & water pump", appItem: "Timing belt & water pump", acura: "105,000 mi or 7 yr"),
        .init(code: "4", work: "Spark plugs", appItem: "Spark plugs", acura: "105,000 mi or 7 yr"),
        .init(code: "5", work: "Engine coolant", appItem: "Engine coolant", acura: "75,000–105,000 mi"),
        .init(code: "6", work: "Rear differential fluid (SH-AWD)", appItem: "Rear differential fluid", acura: "15,000–30,000 mi"),
        .init(code: "—", work: "Brake fluid", appItem: "Brake fluid", acura: "3 yr"),
        .init(code: "—", work: "Wheel alignment", appItem: "Wheel alignment", acura: "12,000 mi or 12 mo"),
        .init(code: "—", work: "Valve adjustment", appItem: "Valve adjustment", acura: "150,000 mi or as needed")
    ]
}
