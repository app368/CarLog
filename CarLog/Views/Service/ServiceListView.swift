import SwiftUI
import SwiftData

// Задача: вкладка Service — нормативы сверху, ниже история регламентных работ
struct ServiceListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ServiceEntry.date, order: .reverse) private var entries: [ServiceEntry]
    @Query(sort: \MaintenanceItem.name) private var schedule: [MaintenanceItem]
    @Query private var fuel: [FuelEntry]
    @State private var isAdding = false
    @State private var isAddingItem = false
    @State private var editingItem: MaintenanceItem?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(schedule) { item in
                        Button { editingItem = item } label: {
                            MaintenanceRow(item: item, currentOdometer: currentOdometer)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteItems)
                    Button("Add Item", systemImage: "plus") { isAddingItem = true }
                } header: {
                    Text("Schedule")
                } footer: {
                    if let currentOdometer {
                        Text("Current odometer: \(currentOdometer.asMiles)")
                    }
                }
                Section("History") {
                    if entries.isEmpty {
                        Text("No service records yet. Tap + to add one.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(entries) { entry in
                        NavigationLink(value: entry) {
                            ServiceRow(entry: entry)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Service")
            .navigationDestination(for: ServiceEntry.self) { ServiceDetailView(entry: $0) }
            .toolbar {
                Button("Add", systemImage: "plus") { isAdding = true }
            }
            .sheet(isPresented: $isAdding) {
                ServiceFormView(entry: nil)
            }
            .sheet(isPresented: $isAddingItem) {
                MaintenanceFormView(item: nil, currentOdometer: currentOdometer)
            }
            .sheet(item: $editingItem) {
                MaintenanceFormView(item: $0, currentOdometer: currentOdometer)
            }
        }
    }

    private var currentOdometer: Int? {
        Odometer.current(fuel: fuel, service: entries)
    }

    // Задача: удаление записей истории свайпом
    private func delete(at offsets: IndexSet) {
        offsets.map { entries[$0] }.forEach(context.delete)
    }

    // Задача: удаление нормативов свайпом
    private func deleteItems(at offsets: IndexSet) {
        offsets.map { schedule[$0] }.forEach(context.delete)
    }
}

// Задача: строка норматива — название и состояние, ниже интервал и срок
struct MaintenanceRow: View {
    let item: MaintenanceItem
    let currentOdometer: Int?

    var body: some View {
        let status = item.status(currentOdometer: currentOdometer)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.name)
                Spacer()
                Text(status.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color(for: status))
            }
            Text(details(status: status))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }

    private func details(status: MaintenanceStatus) -> String {
        let due = item.dueText(currentOdometer: currentOdometer)
        guard status != .noRecord, !due.isEmpty else { return item.intervalText }
        return "\(item.intervalText) · \(due)"
    }

    private func color(for status: MaintenanceStatus) -> Color {
        switch status {
        case .noRecord: .secondary
        case .ok: .green
        case .soon: Color("StatusSoon")
        case .overdue: .red
        }
    }
}

// Задача: строка истории — что сделано и сумма, ниже дата и пробег
struct ServiceRow: View {
    let entry: ServiceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.work.isEmpty ? "Service" : entry.work)
                    .lineLimit(1)
                Spacer()
                Text(entry.amount.asMoney)
            }
            .font(.headline)
            Text(details)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var details: String {
        let date = entry.date.formatted(date: .abbreviated, time: .omitted)
        guard let miles = entry.odometer else { return date }
        return "\(date) · \(miles.asMiles)"
    }
}
