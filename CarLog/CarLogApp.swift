import SwiftUI
import SwiftData

// Задача: точка входа приложения и подключение хранилища SwiftData
@main
struct CarLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [FuelEntry.self, Station.self, FuelGrade.self, InsuranceEntry.self, ServiceEntry.self,
                            MaintenanceItem.self, CarProfile.self])
    }
}
