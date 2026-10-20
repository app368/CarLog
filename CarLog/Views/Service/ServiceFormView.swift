import SwiftUI
import SwiftData

// Задача: форма добавления и правки регламентных работ
struct ServiceFormView: View {
    let entry: ServiceEntry?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date.now
    @State private var odometer = ""
    @State private var amount = ""
    @State private var work = ""
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    NumberField(title: "Odometer", text: $odometer, unit: "mi", keyboard: .numberPad)
                    NumberField(title: "Amount", text: $amount, unit: "USD")
                }
                Section("Work done") {
                    TextField("Oil change, filters…", text: $work, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(entry == nil ? "New Service" : "Edit Service")
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

    // Задача: при правке заполнить форму из записи
    private func load() {
        guard !didLoad, let entry else { return }
        didLoad = true
        date = entry.date
        odometer = entry.odometer.map(String.init) ?? ""
        amount = NumberInput.text(entry.amount)
        work = entry.work
    }

    // Задача: сохранить — обновить существующую запись или создать новую
    private func save() {
        guard let value = NumberInput.double(amount) else { return }
        let miles = NumberInput.int(odometer)
        let cleanWork = work.trimmingCharacters(in: .whitespacesAndNewlines)
        if let entry {
            entry.date = date
            entry.odometer = miles
            entry.amount = value
            entry.work = cleanWork
        } else {
            context.insert(ServiceEntry(date: date, odometer: miles, amount: value, work: cleanWork))
        }
        dismiss()
    }
}
