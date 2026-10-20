import SwiftUI
import SwiftData

// Задача: вкладка Service — список регламентных работ
struct ServiceListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ServiceEntry.date, order: .reverse) private var entries: [ServiceEntry]
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    NavigationLink(value: entry) {
                        ServiceRow(entry: entry)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Service")
            .navigationDestination(for: ServiceEntry.self) { ServiceDetailView(entry: $0) }
            .toolbar {
                Button("Add", systemImage: "plus") { isAdding = true }
            }
            .sheet(isPresented: $isAdding) {
                ServiceFormView(entry: nil)
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView("No service records", systemImage: "wrench.and.screwdriver",
                                           description: Text("Tap + to add a service visit."))
                }
            }
        }
    }

    // Задача: удаление свайпом
    private func delete(at offsets: IndexSet) {
        offsets.map { entries[$0] }.forEach(context.delete)
    }
}

// Задача: строка списка — что сделано и сумма, ниже дата и пробег
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
