import SwiftUI

// Задача: карточка продления регистрации — кто выдал, сумма, даты; ниже документы
// (регистрационная карточка) и примечание, которое правится прямо здесь. Edit правит поля
struct RegistrationDetailView: View {
    let entry: RegistrationEntry
    @State private var isEditing = false
    @FocusState private var isEditingNotes: Bool

    var body: some View {
        List {
            Section {
                LabeledContent("Issued by", value: entry.issuedBy.isEmpty ? "—" : entry.issuedBy)
                LabeledContent("Fee", value: entry.amount > 0 ? entry.amount.asMoney : "—")
                LabeledContent("Paid", value: entry.datePaid.formatted(date: .long, time: .omitted))
                LabeledContent("Valid until") {
                    Text(entry.validUntil.formatted(date: .long, time: .omitted))
                        .foregroundStyle(entry.isExpired ? Color.red : Color.secondary)
                }
            }
            AttachedDocumentsSection(pages: entry.sortedPages, fileStem: "Registration \(entry.datePaid.fileDay)") {
                $0.registration = entry
            }
            NotesSection(text: Binding(get: { entry.notes }, set: { entry.notes = $0 }), focus: $isEditingNotes)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Registration")
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
            RegistrationFormView(entry: entry)
        }
    }
}
