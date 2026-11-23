import Foundation

// Задача: что показать справа или под строкой руководства — кнопку звонка, ссылку или данные из приложения
enum GuideAction {
    case call(role: String)     // номер из справочника Emergency contacts по метке записи
    case claims                 // Claims (24/7) из карточки страховой
    case dmvReport              // номер DMV и ссылка на отчёт онлайн
    case yourInsurance          // страховая и номер полиса из приложения
    case yourCar                // машина и номерной знак из Info → Car
}

// Задача: строка руководства — номер (2.1), текст по-английски и под ним по-русски
struct GuideItem: Identifiable {
    let id: String
    let en: String
    let ru: String
    let action: GuideAction?
}

// Задача: раздел руководства; в разделе-предупреждении (Don't) птичек нет — только значок ⚠
struct GuideSection: Identifiable {
    let id: Int
    let en: String
    let ru: String
    let isWarning: Bool
    let items: [GuideItem]

    init(_ number: Int, _ en: String, _ ru: String, isWarning: Bool = false,
         items: [(en: String, ru: String, action: GuideAction?)]) {
        self.id = number
        self.en = en
        self.ru = ru
        self.isWarning = isWarning
        self.items = items.enumerated().map { index, item in
            GuideItem(id: "\(number).\(index + 1)", en: item.en, ru: item.ru, action: item.action)
        }
    }
}

// Задача: руководство «Что делать при ДТП» для Орегона — по правилам Oregon DMV (Collision Reporting and
// Responsibilities), сверено 22 ноября 2026. Номера телефонов здесь не хранятся — они берутся из справочников
enum AccidentGuide {
    static let source = "Based on Oregon DMV rules: Collision Reporting and Responsibilities. Checked November 2026."

    static let sections: [GuideSection] = [
        GuideSection(1, "Stop and stay safe", "Остановитесь и обезопасьте себя", items: [
            ("Stop at the scene or as close as you safely can. Turn on hazard lights.",
             "Остановитесь на месте ДТП или как можно ближе, если там опасно. Включите аварийку.", nil),
            ("Nobody hurt and the car drives? Move it to the shoulder, out of traffic.",
             "Никто не пострадал и машина на ходу? Уберите её на обочину, с проезжей части.", nil),
            ("Help anyone hurt, but don't move them unless there is danger, such as fire.",
             "Помогите пострадавшим, но не перемещайте их, если нет опасности, например пожара.", nil)
        ]),
        GuideSection(2, "Call", "Позвоните", items: [
            ("911 — anyone hurt, a car blocks the road, fire or leaking fuel, the other driver leaves or seems drunk.",
             "911 — есть пострадавшие, машина перекрыла дорогу, пожар или течёт топливо, другой водитель уезжает или кажется пьяным.",
             .call(role: "emergency")),
            ("No injuries, in Portland — police non-emergency line.",
             "Без пострадавших, в Портленде — полиция, не экстренная линия.", .call(role: "police")),
            ("No injuries, on a highway — Oregon State Police.",
             "Без пострадавших, на шоссе — полиция штата.", .call(role: "statePolice")),
            ("Your insurance — from the scene or right after.",
             "Ваша страховая — с места ДТП или сразу после.", .claims)
        ]),
        GuideSection(3, "Your details — give them to the other driver", "Ваши данные — передайте другому водителю", items: [
            ("Oregon law: name, address, driver license number, license plate, insurance.",
             "По закону Орегона: имя, адрес, номер водительских прав, номерной знак, страховка.", nil),
            ("Insurance", "Страховая и номер полиса — из карточки страховой.", .yourInsurance),
            ("Car", "Машина и номерной знак — из Info → Car.", .yourCar)
        ]),
        GuideSection(4, "Take photos", "Сфотографируйте", items: [
            ("The other driver's license, insurance card and registration.",
             "Права, страховку и регистрацию машины другого водителя.", nil),
            ("License plates of every car.", "Номерные знаки всех машин.", nil),
            ("Damage on every car: close up and from a few steps back.",
             "Повреждения всех машин — вблизи и с нескольких шагов.", nil),
            ("The scene: where the cars stopped, skid marks, signs and lights, road and weather.",
             "Место ДТП: где остановились машины, следы торможения, знаки и светофоры, дорогу и погоду.", nil),
            ("The other driver and their car.", "Другого водителя и его машину.", nil),
            ("Witnesses: name and phone. Police: officer's name and report number.",
             "Свидетели — имя и телефон. Полиция — имя офицера и номер протокола.", nil)
        ]),
        GuideSection(5, "Don't", "Чего не делать", isWarning: true, items: [
            ("Don't leave before you exchange information — leaving the scene is a crime.",
             "Не уезжайте, пока не обменялись данными, — уехать с места ДТП это преступление.", nil),
            ("Don't say \"it was my fault\" and don't argue. Stick to facts.",
             "Не говорите «я виноват» и не спорьте. Только факты.", nil),
            ("Don't sign anything except a police ticket.",
             "Ничего не подписывайте, кроме квитанции полиции (ticket).", nil),
            ("Don't take or offer cash to settle on the spot.",
             "Не берите и не предлагайте деньги, чтобы решить всё на месте.", nil)
        ]),
        GuideSection(6, "Within 72 hours", "В течение 72 часов", items: [
            ("File the DMV crash report if anyone was hurt, damage to your car is over $2,500, or a car was towed "
                + "and damage is over $2,500. You need it even if the police made a report.",
             "Подайте отчёт о ДТП в DMV, если есть пострадавшие, ущерб вашей машине больше $2,500 или машину "
                + "эвакуировали и ущерб больше $2,500. Нужно, даже если полиция составила протокол.", .dmvReport),
            ("Call your insurance if you haven't yet.", "Позвоните в страховую, если ещё не звонили.", .claims),
            ("Pain shows up later? See a doctor — some injuries appear after a day or two.",
             "Появилась боль позже? Сходите к врачу — некоторые травмы проявляются через день-два.", nil)
        ])
    ]
}
