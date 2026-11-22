import Foundation

// Задача: группа работ — что делается обязательно вместе, что обычно вместе,
// что сказано в регламенте Acura и как это делают сервисные центры
struct ServiceGroup: Identifiable {
    let name: String
    let required: [String]
    let usual: [String]
    let acura: String
    let centers: [String]

    var id: String { name }

    // Все работы группы — для подписи в списке и поиска группы по работе
    var services: [String] { required + usual }
}

// Задача: справочник групп работ — справочный, только для чтения (Maintenance → Reference → Service groups).
// Составлен по таблице Acura Maintenance Minder для MDX 2014–2015 и документам из сервисов;
// пополняется по мере разбора новых документов
enum ServiceGroups {
    static let all: [ServiceGroup] = [
        ServiceGroup(
            name: "Timing belt service",
            required: ["Timing belt", "Water pump", "Drive belt"],
            usual: ["Timing belt tensioner", "Engine coolant", "Spark plugs"],
            acura: "Code 4: timing belt, tensioner, water pump, drive belt and spark plugs. "
                + "The water pump is driven by the timing belt, and the drive belt comes off to reach it. "
                + "Coolant is drained when the water pump is replaced, so a full coolant change (code 5) fits here too.",
            centers: ["Acura dealer, Oct 2025: timing belt, water pump, drive belts and coolant refill in one line; "
                + "tensioner in a separate line. Coolant was only topped off, not replaced."]),
        ServiceGroup(
            name: "Oil service",
            required: [],
            usual: ["Oil & filter change", "Tire rotation"],
            acura: "Codes A or B with 1: Maintenance Minder often shows them together (A1, B1).",
            centers: []),
        ServiceGroup(
            name: "Air filters",
            required: [],
            usual: ["Engine air filter", "Cabin air filter"],
            acura: "Code 2: both filters.",
            centers: ["Acura dealer, Oct 2025: cabin filter only."]),
        ServiceGroup(
            name: "Transmission fluids",
            required: [],
            usual: ["Transmission fluid (ATF)", "Transfer case fluid"],
            acura: "Code 3: ATF and transfer case fluid (SH-AWD).",
            centers: ["Acura dealer, Oct 2025: transfer case fluid only."])
    ]

    // Работы, которые делаются отдельно, без группы
    static let separate = ["Rear differential fluid", "Brake fluid", "Wheel alignment", "Valve adjustment"]

    // Задача: группа, в которую входит работа, — для строки Group в карточке работы
    static func group(for serviceName: String) -> ServiceGroup? {
        all.first { $0.services.contains(serviceName) }
    }
}
