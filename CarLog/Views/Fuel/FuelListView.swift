import SwiftUI
import SwiftData

// Задача: главный экран вкладки Fuel — список заправок
struct FuelListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FuelEntry.date, order: .reverse) private var entries: [FuelEntry]
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(entries) { entry in
                        NavigationLink(value: entry) {
                            FuelRow(entry: entry)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Fuel")
            .navigationDestination(for: FuelEntry.self) { FuelDetailView(entry: $0) }
            .toolbar {
                Button("Add", systemImage: "plus") { isAdding = true }
            }
            .sheet(isPresented: $isAdding) {
                FuelFormView(entry: nil)
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView("No fill-ups yet", systemImage: "fuelpump",
                                           description: Text("Tap + to add your first fill-up."))
                }
            }
        }
    }

    // Задача: удаление свайпом
    private func delete(at offsets: IndexSet) {
        offsets.map { entries[$0] }.forEach(context.delete)
    }
}

// Задача: строка списка — дата и стоимость, ниже заправка, объём и цена
struct FuelRow: View {
    let entry: FuelEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.date, format: .dateTime.month(.abbreviated).day().year())
                Spacer()
                Text(entry.total.asMoney)
            }
            .font(.headline)
            HStack {
                Text(entry.station?.name ?? "No station")
                Spacer()
                Text("\(entry.gallons.asGallons) · \(entry.pricePerGallon.asPricePerGallon)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
