import SwiftUI
import SwiftData

// Задача: вкладка Insurance — список оплат страховки
struct InsuranceListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \InsuranceEntry.datePaid, order: .reverse) private var entries: [InsuranceEntry]
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    NavigationLink(value: entry) {
                        InsuranceRow(entry: entry)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Insurance")
            .navigationDestination(for: InsuranceEntry.self) { InsuranceDetailView(entry: $0) }
            .toolbar {
                Button("Add", systemImage: "plus") { isAdding = true }
            }
            .sheet(isPresented: $isAdding) {
                InsuranceFormView(entry: nil)
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView("No insurance records", systemImage: "checkmark.shield",
                                           description: Text("Tap + to add a payment."))
                }
            }
        }
    }

    // Задача: удаление свайпом
    private func delete(at offsets: IndexSet) {
        offsets.map { entries[$0] }.forEach(context.delete)
    }
}

// Задача: строка списка — компания и сумма, ниже срок действия полиса
struct InsuranceRow: View {
    let entry: InsuranceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.company.isEmpty ? "Insurance" : entry.company)
                Spacer()
                Text(entry.amount.asMoney)
            }
            .font(.headline)
            Text(entry.isExpired
                 ? "Expired \(entry.validUntil.formatted(date: .abbreviated, time: .omitted))"
                 : "Valid until \(entry.validUntil.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(entry.isExpired ? Color.red : Color.secondary)
        }
    }
}
