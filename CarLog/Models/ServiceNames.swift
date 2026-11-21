import Foundation

// Задача: таблица переводов названий работ — справочная, только для чтения (вкладка Info → Service names)
enum ServiceNames {
    static let rows: [(english: String, russian: String)] = [
        ("Oil & filter change", "Замена масла и масляного фильтра"),
        ("Tire rotation", "Ротация шин"),
        ("Engine air filter", "Воздушный фильтр двигателя"),
        ("Cabin air filter", "Фильтр салона"),
        ("Transmission fluid (ATF)", "Масло автоматической коробки"),
        ("Transfer case fluid", "Масло раздаточной коробки"),
        ("Rear differential fluid", "Масло заднего дифференциала"),
        ("Engine coolant", "Охлаждающая жидкость"),
        ("Timing belt", "Ремень ГРМ"),
        ("Timing belt tensioner", "Натяжитель ремня ГРМ"),
        ("Water pump", "Водяная помпа"),
        ("Drive belt", "Приводной ремень"),
        ("Spark plugs", "Свечи зажигания"),
        ("Brake fluid", "Тормозная жидкость"),
        ("Wheel alignment", "Развал-схождение"),
        ("Valve adjustment", "Регулировка клапанов")
    ]
}
