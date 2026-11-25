import Foundation

// Задача: одна проверка — английское название, русское и пояснение (если нужно)
struct MaintenanceCheck: Identifiable {
    let english: String
    let russian: String
    let note: String?

    var id: String { english }

    init(_ english: String, _ russian: String, note: String? = nil) {
        self.english = english
        self.russian = russian
        self.note = note
    }
}

// Задача: группа проверок одного узла — подзаголовок (может не быть), проверки и сноска под ними
struct MaintenanceCheckGroup: Identifiable {
    let title: String?
    let checks: [MaintenanceCheck]
    let footnote: String?

    var id: String { title ?? checks.first?.english ?? "" }

    init(_ title: String?, footnote: String? = nil, _ checks: [MaintenanceCheck]) {
        self.title = title
        self.checks = checks
        self.footnote = footnote
    }
}

// Задача: раздел по поводу заезда — заголовок на двух языках, когда и где это делают, группы проверок
struct MaintenanceCheckSection: Identifiable {
    let english: String
    let russian: String
    let intro: String
    let groups: [MaintenanceCheckGroup]

    var id: String { english }
}

// Задача: справочник проверок при обслуживании — справочный, только для чтения
// (Maintenance → Reference → Maintenance checks). Разложен по поводу заезда: каждый раз, раз в год, по поводу.
// Копия для правок — Maintenance-Checks.md в папке проекта; пополняется по мере разбора документов из сервисов
enum MaintenanceChecks {
    static let sections: [MaintenanceCheckSection] = [
        MaintenanceCheckSection(
            english: "1. Every visit", russian: "Каждый заезд",
            intro: "Проверки при замене масла в любом сервисе: 5–10 минут, обычно бесплатно — входят в цену замены. Acura — код A: долить жидкости, выставить давление в шинах.",
            groups: [
                MaintenanceCheckGroup("Fluids under the hood · Жидкости под капотом", [
                    MaintenanceCheck("Top up under-hood fluids", "Долить жидкости под капотом",
                                     note: "Бачки с метками MIN и MAX: антифриз, тормозная жидкость, гидроусилитель руля, омывайка."),
                    MaintenanceCheck("Brake fluid level", "Уровень тормозной жидкости"),
                    MaintenanceCheck("Power steering fluid level", "Уровень жидкости гидроусилителя руля"),
                    MaintenanceCheck("Coolant reservoir level", "Уровень антифриза в расширительном бачке",
                                     note: "Крышку на горячем двигателе не открывать — система под давлением."),
                    MaintenanceCheck("Windshield wash fluid level", "Уровень омывающей жидкости")
                ]),
                MaintenanceCheckGroup("Engine oil · Моторное масло", [
                    MaintenanceCheck("Oil drain plug & gasket", "Сливная пробка и шайба",
                                     note: "Болт внизу поддона двигателя, через него сливают старое масло. Шайбу Acura советует менять при каждой замене масла, иначе может подтекать."),
                    MaintenanceCheck("Oil change evacuation", "Масло откачано через щуп",
                                     note: "Насосом сверху, пробку не откручивали — поэтому её и не проверяли."),
                    MaintenanceCheck("Oil service indicator reset", "Сброс индикатора обслуживания",
                                     note: "Maintenance Minder на приборке: после замены масла ресурс сбрасывают на 100%, иначе машина продолжит напоминать. Можно сделать и самому.")
                ]),
                MaintenanceCheckGroup("Tires and electrical · Шины и электрика", [
                    MaintenanceCheck("Check and set tire pressures", "Проверить и выставить давление в шинах"),
                    MaintenanceCheck("12V battery", "Аккумулятор 12 В",
                                     note: "Быстрая проверка. Тест прибором — в разделе «По поводу».")
                ])
            ]),
        MaintenanceCheckSection(
            english: "2. Full inspection — yearly or code B", russian: "Полный осмотр — раз в год или с кодом B",
            intro: "Дилер или мастерская, машина на подъёмнике. Acura — код B, примерно каждые 7 500–20 000 миль.",
            groups: [
                MaintenanceCheckGroup("Brakes · Тормоза", [
                    MaintenanceCheck("Front and rear brake pads, rotors and calipers", "Передние и задние колодки, диски и суппорты"),
                    MaintenanceCheck("Parking brake adjustment", "Регулировка стояночного тормоза"),
                    MaintenanceCheck("Brake hoses and lines, including VSA lines", "Тормозные шланги и трубки",
                                     note: "Включая линии системы стабилизации VSA.")
                ]),
                MaintenanceCheckGroup("Steering and suspension · Рулевое управление и подвеска", [
                    MaintenanceCheck("Tie rod ends, steering gearbox and gearbox boots", "Рулевые наконечники, рулевая рейка и её пыльники"),
                    MaintenanceCheck("Suspension components", "Детали подвески"),
                    MaintenanceCheck("Drive shaft boots", "Пыльники приводных валов (ШРУСов)",
                                     note: "Порванный пыльник пропускает грязь в шарнир — потом дорогой ремонт.")
                ]),
                MaintenanceCheckGroup("Fluids, exhaust, fuel · Жидкости, выхлоп, топливо", [
                    MaintenanceCheck("Inspect all fluid levels and condition of fluids", "Уровень и состояние всех жидкостей",
                                     note: "Не только сколько, но и какая: цвет, запах, грязь."),
                    MaintenanceCheck("Exhaust system", "Выхлопная система"),
                    MaintenanceCheck("Fuel lines and connections", "Топливные трубки и соединения")
                ]),
                MaintenanceCheckGroup("General · Общее", [
                    MaintenanceCheck("Road test vehicle", "Пробная поездка")
                ])
            ]),
        MaintenanceCheckSection(
            english: "3. When there is a reason", russian: "По поводу",
            intro: "Подошёл код Maintenance Minder, есть симптом или сервис что-то предлагает.",
            groups: [
                MaintenanceCheckGroup(nil, [
                    MaintenanceCheck("Inspect drive belt", "Осмотр приводного ремня",
                                     note: "С кодом 2 (каждые 15 000–30 000 миль) или если ремень свистит."),
                    MaintenanceCheck("Hand torque all lug nuts", "Подтянуть колёсные гайки",
                                     note: "После ротации шин (код 1) или любой работы со снятием колёс."),
                    MaintenanceCheck("Battery test", "Тест аккумулятора прибором",
                                     note: "Тугой запуск, зима, аккумулятору 4–5 лет. У дилера — прибором Acura ED-18.")
                ]),
                MaintenanceCheckGroup("Sealed units · Герметичные узлы",
                                      footnote: "Щупа нет, проверить сложно — в инвойсе обычно Sealed или Not Checked. Если сервис предлагает замену, сначала свериться со сроком в Schedule.", [
                    MaintenanceCheck("Transmission fluid level", "Уровень масла в коробке передач (ATF)"),
                    MaintenanceCheck("Transfer case fluid level", "Уровень масла в раздаточной коробке"),
                    MaintenanceCheck("Rear differential fluid level", "Уровень масла в заднем дифференциале")
                ])
            ]),
        MaintenanceCheckSection(
            english: "4. Not for MDX", russian: "Не про MDX",
            intro: "Встречается в чек-листах сервисов, но к этой машине не относится.",
            groups: [
                MaintenanceCheckGroup(nil, [
                    MaintenanceCheck("Front differential fluid level", "Уровень масла в переднем дифференциале",
                                     note: "У MDX передний дифференциал внутри коробки и работает на её масле — отдельной жидкости нет."),
                    MaintenanceCheck("Lubrication points", "Точки смазки",
                                     note: "У современных машин шарниры герметичные, смазывать нечего — в инвойсе Sealed.")
                ])
            ])
    ]

    // Задача: как сервисы пишут итог проверки в документе
    static let results: [MaintenanceCheck] = [
        MaintenanceCheck("Checked-OK", "Проверили, в норме"),
        MaintenanceCheck("Not Checked", "Не проверяли"),
        MaintenanceCheck("Sealed", "Узел герметичный, нет щупа или пробки — проверить нельзя"),
        MaintenanceCheck("Added", "Долили"),
        MaintenanceCheck("Reset", "Сбросили")
    ]

    static let notes = [
        "По таблице Acura: если Maintenance Minder целый год не просит обслуживания, всё равно заменить масло и проверить уровни жидкостей и давление в шинах.",
        "В инвойсе быстрого сервиса уровень масла в заднем дифференциале отмечен Not Checked, а масло там всё равно заменили."
    ]

    static let source = "Sources: Acura dealer Maintenance Minder chart for 2014–2015 MDX (codes A, B, 1, 2); "
        + "Acura dealer invoice, Oct 2025; quick oil change service invoice, May 2026."
}
