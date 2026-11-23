import SwiftUI
import SwiftData

// Задача: форма добавления и правки продления регистрации. В новой записи «кто выдал» подставляется
// из прошлой, срок — через 2 года. Сумма необязательна
struct RegistrationFormView: View {
    let entry: RegistrationEntry?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RegistrationEntry.datePaid, order: .reverse) private var allEntries: [RegistrationEntry]

    @State private var issuedBy = ""
    @State private var amount = ""
    @State private var datePaid = Date.now
    @State private var validUntil = Calendar.current.date(byAdding: .year, value: 2, to: .now) ?? .now
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Issued by") {
                        TextField("e.g. Oregon DMV", text: $issuedBy)
                            .multilineTextAlignment(.trailing)
                    }
                    NumberField(title: "Fee", text: $amount, unit: "USD")
                }
                Section {
                    DatePicker("Paid", selection: $datePaid, displayedComponents: .date)
                    DatePicker("Valid until", selection: $validUntil, displayedComponents: .date)
                }
            }
            .keyboardDoneButton()
            .navigationTitle(entry == nil ? "New Registration" : "Edit Registration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .onAppear(perform: load)
        }
    }

    // Задача: заполнить форму — из записи при правке, «кто выдал» из последней записи при добавлении
    private func load() {
        guard !didLoad else { return }
        didLoad = true
        if let entry {
            issuedBy = entry.issuedBy
            amount = entry.amount > 0 ? NumberInput.text(entry.amount) : ""
            datePaid = entry.datePaid
            validUntil = entry.validUntil
        } else if let last = allEntries.first {
            issuedBy = last.issuedBy
        }
    }

    // Задача: сохранить — обновить существующую запись или создать новую; пустая сумма сохраняется как 0
    private func save() {
        let value = NumberInput.double(amount) ?? 0
        let name = issuedBy.trimmingCharacters(in: .whitespaces)
        let target = entry ?? RegistrationEntry(issuedBy: name, datePaid: datePaid, validUntil: validUntil, amount: value)
        if entry == nil { context.insert(target) }
        target.issuedBy = name
        target.amount = value
        target.datePaid = datePaid
        target.validUntil = validUntil
        dismiss()
    }
}
