import SwiftUI
import SwiftData

// Задача: карточка оплаты страховки — компания (тап открывает её карточку с контактами), номер полиса,
// сумма, даты; ниже документы (страховая карточка, полис) и примечание, которое правится прямо здесь.
// Edit правит поля
struct InsuranceDetailView: View {
    let entry: InsuranceEntry
    // Все записи этого вида — чтобы понять, заменена ли истёкшая более поздней
    @Query private var allEntries: [InsuranceEntry]
    @State private var isEditing = false
    @FocusState private var isEditingNotes: Bool

    var body: some View {
        List {
            Section {
                if let insurer = entry.insurer {
                    NavigationLink {
                        InsuranceCompanyDetailView(company: insurer)
                    } label: {
                        LabeledContent("Company", value: insurer.name)
                    }
                } else {
                    LabeledContent("Company", value: entry.companyName.isEmpty ? "—" : entry.companyName)
                }
                LabeledContent("Policy number") {
                    Text(entry.policyNumber.isEmpty ? "—" : entry.policyNumber)
                        .textSelection(.enabled)
                }
                LabeledContent("Amount", value: entry.amount > 0 ? entry.amount.asMoney : "—")
                LabeledContent("Paid", value: entry.datePaid.formatted(date: .long, time: .omitted))
                LabeledContent("Valid until") {
                    Text(entry.validUntil.formatted(date: .long, time: .omitted))
                        .foregroundStyle(validity.color)
                }
            }
            AttachedDocumentsSection(pages: entry.sortedPages, fileStem: "Insurance \(entry.datePaid.fileDay)") {
                $0.insurance = entry
            }
            NotesSection(text: Binding(get: { entry.notes }, set: { entry.notes = $0 }), focus: $isEditingNotes)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Insurance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Пока правится примечание, вместо Edit — Done: он закрывает клавиатуру
            if isEditingNotes {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isEditingNotes = false }
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { isEditing = true }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            InsuranceFormView(entry: entry)
        }
    }

    // Задача: состояние срока — зелёный, жёлтый за 30 дней до конца, красный, если пора продлевать;
    // синий, если уже есть более поздняя запись
    private var validity: Validity {
        Validity(validUntil: entry.validUntil, newest: allEntries.map(\.validUntil).max())
    }
}

// Задача: примечание внизу карточки — правится прямо здесь, поле растёт вместе с текстом.
// Общее для карточек страховки и регистрации
struct NotesSection: View {
    @Binding var text: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        Section("Notes") {
            TextField("Anything worth remembering", text: $text, axis: .vertical)
                .focused(focus)
                .clearButton(text: $text)
        }
    }
}
