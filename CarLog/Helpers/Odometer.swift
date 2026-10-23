import Foundation

// Задача: текущий пробег — наибольшее значение одометра среди заправок и регламентных работ
enum Odometer {
    static func current(fuel: [FuelEntry], service: [ServiceEntry]) -> Int? {
        (fuel.compactMap(\.odometer) + service.compactMap(\.odometer)).max()
    }
}
