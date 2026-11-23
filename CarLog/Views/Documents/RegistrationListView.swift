import SwiftUI
import SwiftData

// Задача: раздел Registration вкладки Documents — продления регистрации, новые сверху.
// Свайп удаляет после подтверждения
struct RegistrationListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RegistrationEntry.datePaid, order: .reverse) private var entries: [RegistrationEntry]
    @State private var pendingDelete: RegistrationEntry?

    var body: some View {
        List {
            ForEach(entries) { entry in
                RegistrationRow(entry: entry)
            }
            .onDelete { offsets in pendingDelete = offsets.map { entries[$0] }.first }
        }
        .alert("Delete registration?", isPresented: Binding(get: { pendingDelete != nil },
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
                ContentUnavailableView("No registration records", systemImage: "car",
                                       description: Text("Tap + to add a registration."))
            }
        }
    }
}

// Задача: строка списка — кто выдал и сумма (если введена), ниже срок действия
struct RegistrationRow: View {
    let entry: RegistrationEntry

    var body: some View {
        PeriodRow(title: entry.issuedBy.isEmpty ? "Registration" : entry.issuedBy,
                  amount: entry.amount, validUntil: entry.validUntil, isExpired: entry.isExpired)
    }
}
