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
                    InsuranceRow(entry: entry, newest: newest)
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

    // Самый поздний срок среди всех оплат — по нему видно, заменена ли истёкшая
    private var newest: Date? {
        entries.map(\.validUntil).max()
    }
}

// Задача: строка списка — компания и сумма (если введена), ниже срок действия полиса
struct InsuranceRow: View {
    let entry: InsuranceEntry
    let newest: Date?

    var body: some View {
        PeriodRow(title: entry.companyName.isEmpty ? "Insurance" : entry.companyName,
                  amount: entry.amount, validUntil: entry.validUntil,
                  validity: Validity(validUntil: entry.validUntil, newest: newest))
    }
}

// Задача: строка списка документов — название и сумма, ниже «Valid until …» или «Expired …»
// красным (пора продлевать) или синим (уже заменена). Общая для страховки и регистрации
struct PeriodRow: View {
    let title: String
    let amount: Double
    let validUntil: Date
    let validity: Validity

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
            Text(validity == .valid
                 ? "Valid until \(validUntil.formatted(date: .abbreviated, time: .omitted))"
                 : "Expired \(validUntil.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(validity.color)
        }
    }
}

// Задача: состояние срока действия записи — по нему красится срок в списке и карточке.
// Действует — серый; истёк, а записи с более поздним сроком нет — красный, пора продлевать;
// истёк, но уже есть запись с более поздним сроком — синий, запись заменена
enum Validity {
    case valid, expired, replaced

    // newest — самый поздний срок среди всех записей этого вида (страховки или регистрации)
    init(validUntil: Date, newest: Date?) {
        if validUntil >= Calendar.current.startOfDay(for: .now) {
            self = .valid
        } else if let newest, newest > validUntil {
            self = .replaced
        } else {
            self = .expired
        }
    }

    var color: Color {
        switch self {
        case .valid: .secondary
        case .expired: .red
        case .replaced: .blue
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
