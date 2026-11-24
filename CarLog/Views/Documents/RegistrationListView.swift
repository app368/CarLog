import SwiftUI
import SwiftData

// Задача: раздел Registration вкладки Documents — продления регистрации, новые сверху.
// Тап открывает карточку, «+» — новую запись, свайп удаляет после подтверждения
struct RegistrationListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RegistrationEntry.datePaid, order: .reverse) private var entries: [RegistrationEntry]
    @State private var isAdding = false
    @State private var pendingDelete: RegistrationEntry?

    var body: some View {
        List {
            ForEach(entries) { entry in
                NavigationLink {
                    RegistrationDetailView(entry: entry)
                } label: {
                    RegistrationRow(entry: entry, newest: newest)
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
            RegistrationFormView(entry: nil)
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

    // Самый поздний срок среди всех регистраций — по нему видно, заменена ли истёкшая
    private var newest: Date? {
        entries.map(\.validUntil).max()
    }
}

// Задача: строка списка — кто выдал и сумма (если введена), ниже срок действия
struct RegistrationRow: View {
    let entry: RegistrationEntry
    let newest: Date?

    var body: some View {
        PeriodRow(title: entry.issuedBy.isEmpty ? "Registration" : entry.issuedBy,
                  amount: entry.amount, validUntil: entry.validUntil,
                  validity: Validity(validUntil: entry.validUntil, newest: newest))
    }
}
