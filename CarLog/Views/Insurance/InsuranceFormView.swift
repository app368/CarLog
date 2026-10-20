import SwiftUI
import SwiftData

// Задача: форма добавления и правки оплаты страховки
struct InsuranceFormView: View {
    let entry: InsuranceEntry?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \InsuranceEntry.datePaid, order: .reverse) private var allEntries: [InsuranceEntry]

    @State private var company = ""
    @State private var amount = ""
    @State private var datePaid = Date.now
    @State private var validUntil = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Company", text: $company)
                    NumberField(title: "Amount", text: $amount, unit: "USD")
                }
                Section {
                    DatePicker("Paid", selection: $datePaid, displayedComponents: .date)
                    DatePicker("Valid until", selection: $validUntil, displayedComponents: .date)
                }
            }
            .keyboardDoneButton()
            .navigationTitle(entry == nil ? "New Payment" : "Edit Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled((NumberInput.double(amount) ?? 0) <= 0)
                }
            }
            .onAppear(perform: load)
        }
    }

    // Задача: заполнить форму — из записи при правке, компанию из последней оплаты при добавлении
    private func load() {
        guard !didLoad else { return }
        didLoad = true
        if let entry {
            company = entry.company
            amount = NumberInput.text(entry.amount)
            datePaid = entry.datePaid
            validUntil = entry.validUntil
        } else {
            company = allEntries.first?.company ?? ""
        }
    }

    // Задача: сохранить — обновить существующую запись или создать новую
    private func save() {
        guard let value = NumberInput.double(amount) else { return }
        let cleanCompany = company.trimmingCharacters(in: .whitespaces)
        if let entry {
            entry.company = cleanCompany
            entry.amount = value
            entry.datePaid = datePaid
            entry.validUntil = validUntil
        } else {
            context.insert(InsuranceEntry(datePaid: datePaid, validUntil: validUntil, amount: value, company: cleanCompany))
        }
        dismiss()
    }
}
