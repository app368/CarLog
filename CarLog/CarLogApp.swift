import SwiftUI
import SwiftData

// Задача: точка входа приложения и подключение хранилища SwiftData
@main
struct CarLogApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [FuelEntry.self, Station.self, FuelGrade.self, InsuranceEntry.self, ServiceEntry.self])
    }
}
