import SwiftUI
import SwiftData

// Задача: таб-бар с тремя вкладками — бензин, страховка, регламентные работы
struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeedFuelGrades") private var didSeedFuelGrades = false

    var body: some View {
        TabView {
            FuelListView()
                .tabItem { Label("Fuel", systemImage: "fuelpump") }
            InsuranceListView()
                .tabItem { Label("Insurance", systemImage: "checkmark.shield") }
            ServiceListView()
                .tabItem { Label("Service", systemImage: "wrench.and.screwdriver") }
        }
        .onAppear(perform: seedFuelGradesIfNeeded)
    }

    // Задача: при первом запуске заполнить справочник марок бензина
    private func seedFuelGradesIfNeeded() {
        guard !didSeedFuelGrades else { return }
        FuelGrade.defaultNames.forEach { context.insert(FuelGrade(name: $0)) }
        didSeedFuelGrades = true
    }
}
