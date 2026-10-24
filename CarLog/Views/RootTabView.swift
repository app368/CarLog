import SwiftUI
import SwiftData

// Задача: таб-бар — бензин, страховка, регламентные работы, графики и данные машины
struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeedFuelGrades") private var didSeedFuelGrades = false
    @AppStorage("didSeedMaintenance") private var didSeedMaintenance = false
    @AppStorage("didApplyMDX2014Schedule") private var didApplyMDX2014Schedule = false

    var body: some View {
        TabView {
            FuelListView()
                .tabItem { Label("Fuel", systemImage: "fuelpump") }
            InsuranceListView()
                .tabItem { Label("Insurance", systemImage: "checkmark.shield") }
            ServiceListView()
                .tabItem { Label("Service", systemImage: "wrench.and.screwdriver") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.xyaxis.line") }
            CarView()
                .tabItem { Label("Car", systemImage: "car") }
        }
        .onAppear(perform: seedIfNeeded)
    }

    // Задача: при первом запуске заполнить справочник марок бензина и нормативы;
    // один раз привести ранее созданные нормативы к регламенту 2014 Acura MDX
    private func seedIfNeeded() {
        if !didSeedFuelGrades {
            FuelGrade.defaultNames.forEach { context.insert(FuelGrade(name: $0)) }
            didSeedFuelGrades = true
        }
        if !didSeedMaintenance || !didApplyMDX2014Schedule {
            let existing = (try? context.fetch(FetchDescriptor<MaintenanceItem>())) ?? []
            MaintenanceItem.applyDefaults(to: existing, in: context)
            didSeedMaintenance = true
            didApplyMDX2014Schedule = true
        }
    }
}
