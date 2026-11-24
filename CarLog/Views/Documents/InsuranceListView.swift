import SwiftUI
import SwiftData

// Задача: раздел Insurance вкладки Documents — оплаты страховки, новые сверху.
// Тап открывает карточку, «+» — новую оплату, свайп удаляет после подтверждения
struct InsuranceListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \InsuranceEntry.datePaid, order: .reverse) private var entries: [InsuranceEntry]
    @State private var isAdding = false
    @State private var pendingDelete: InsuranceEntry?

    var body: some View {
        List {
            ForEach(entries) { entry in
                NavigationLink {
                    InsuranceDetailView(entry: entry)
                } label: {
                    InsuranceRow(entry: entry)
                }
            }
            .onDelete { offsets in pendingDelete = offsets.map { entries[$0] }.first }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") { isAdding = true }
            }
        }
        .sheet(isPresented: $isAdding) {
            InsuranceFormView(entry: nil)
        }
        .alert("Delete payment?", isPresented: Binding(get: { pendingDelete != nil },
                                                       set: { if !$0 { pendingDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let pendingDelete { context.delete(pendingDelete) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text(DeleteText.message(documents: pendingDelete?.pages.count ?? 0))
        }
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView("No insurance records", systemImage: "checkmark.shield",
                                       description: Text("Tap + to add a payment."))
            }
        }
    }
}

// Задача: строка списка — компания и сумма (если введена), ниже срок действия полиса
struct InsuranceRow: View {
    let entry: InsuranceEntry

    var body: some View {
        PeriodRow(title: entry.companyName.isEmpty ? "Insurance" : entry.companyName,
                  amount: entry.amount, validUntil: entry.validUntil, isExpired: entry.isExpired)
    }
}

// Задача: строка списка документов — название и сумма, ниже «Valid until …» или красное «Expired …».
// Общая для страховки и регистрации
struct PeriodRow: View {
    let title: String
    let amount: Double
    let validUntil: Date
    let isExpired: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                if amount > 0 {
                    Text(amount.asMoney)
                }
            }
            .font(.headline)
            Text(isExpired
                 ? "Expired \(validUntil.formatted(date: .abbreviated, time: .omitted))"
                 : "Valid until \(validUntil.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(isExpired ? Color.red : Color.secondary)
        }
    }
}

// Задача: текст подтверждения удаления — предупредить, что документы удалятся вместе с записью
enum DeleteText {
    static func message(documents: Int) -> String {
        switch documents {
        case 0: "This can't be undone."
        case 1: "Its document will be deleted too."
        default: "Its \(documents) documents will be deleted too."
        }
    }
}
