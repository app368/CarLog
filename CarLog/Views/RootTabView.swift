import SwiftUI
import SwiftData

// Задача: таб-бар — бензин, страховка, обслуживание, графики и данные машины
struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeedFuelGrades") private var didSeedFuelGrades = false
    @AppStorage("didSeedMaintenanceV2") private var didSeedMaintenanceV2 = false

    var body: some View {
        TabView {
            FuelListView()
                .tabItem { Label("Fuel", systemImage: "fuelpump") }
            InsuranceListView()
                .tabItem { Label("Insurance", systemImage: "checkmark.shield") }
            MaintenanceView()
                .tabItem { Label("Maintenance", systemImage: "wrench.and.screwdriver") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.xyaxis.line") }
            InfoView()
                .tabItem { Label("Info", systemImage: "info.circle") }
        }
        .onAppear(perform: seedIfNeeded)
    }

    // Задача: при первом запуске заполнить справочник марок бензина и справочник работ.
    // При переходе на новый раздел Maintenance старые нормативы заменяются стартовым набором из 16 работ
    private func seedIfNeeded() {
        if !didSeedFuelGrades {
            FuelGrade.defaultNames.forEach { context.insert(FuelGrade(name: $0)) }
            didSeedFuelGrades = true
        }
        if !didSeedMaintenanceV2 {
            (try? context.fetch(FetchDescriptor<MaintenanceItem>()))?.forEach(context.delete)
            MaintenanceItem.defaults.forEach {
                context.insert(MaintenanceItem(name: $0.name, intervalMiles: $0.miles, intervalMonths: $0.months, note: $0.note))
            }
            didSeedMaintenanceV2 = true
        }
    }
}
