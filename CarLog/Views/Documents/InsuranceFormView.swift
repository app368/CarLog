import SwiftUI
import SwiftData

// Задача: форма добавления и правки оплаты страховки. Компания — из справочника;
// в новой оплате компания и номер полиса подставляются из прошлой, срок — через 6 месяцев. Сумма необязательна
struct InsuranceFormView: View {
    let entry: InsuranceEntry?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \InsuranceEntry.datePaid, order: .reverse) private var allEntries: [InsuranceEntry]

    @State private var company: InsuranceCompany?
    @State private var policyNumber = ""
    @State private var amount = ""
    @State private var datePaid = Date.now
    @State private var validUntil = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        InsuranceCompanyPickerView(selection: $company)
                    } label: {
                        LabeledContent("Company", value: company?.name ?? "None")
                    }
                    LabeledField(title: "Policy number", text: $policyNumber, capitalization: .characters)
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
                }
            }
            .onAppear(perform: load)
        }
    }

    // Задача: заполнить форму — из записи при правке, компанию и номер полиса из последней оплаты при добавлении
    private func load() {
        guard !didLoad else { return }
        didLoad = true
        if let entry {
            company = entry.insurer
            policyNumber = entry.policyNumber
            amount = entry.amount > 0 ? NumberInput.text(entry.amount) : ""
            datePaid = entry.datePaid
            validUntil = entry.validUntil
        } else if let last = allEntries.first {
            company = last.insurer
            policyNumber = last.policyNumber
        }
    }

    // Задача: сохранить — обновить существующую запись или создать новую; пустая сумма сохраняется как 0
    private func save() {
        let value = NumberInput.double(amount) ?? 0
        let target = entry ?? InsuranceEntry(datePaid: datePaid, validUntil: validUntil, amount: value, company: "")
        if entry == nil { context.insert(target) }
        target.insurer = company
        target.policyNumber = policyNumber.trimmingCharacters(in: .whitespaces)
        target.amount = value
        target.datePaid = datePaid
        target.validUntil = validUntil
        dismiss()
    }
}
