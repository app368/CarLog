import SwiftUI
import SwiftData

// Задача: форма норматива — название, интервалы и когда делали в последний раз
struct MaintenanceFormView: View {
    let item: MaintenanceItem?
    let currentOdometer: Int?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var intervalMiles: String
    @State private var intervalMonths: String
    @State private var hasLast: Bool
    @State private var lastDate: Date
    @State private var lastOdometer: String

    init(item: MaintenanceItem?, currentOdometer: Int?) {
        self.item = item
        self.currentOdometer = currentOdometer
        _name = State(initialValue: item?.name ?? "")
        _intervalMiles = State(initialValue: item?.intervalMiles.map(String.init) ?? "")
        _intervalMonths = State(initialValue: item?.intervalMonths.map(String.init) ?? "")
        _hasLast = State(initialValue: item?.lastDate != nil)
        _lastDate = State(initialValue: item?.lastDate ?? .now)
        _lastOdometer = State(initialValue: item?.lastOdometer.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }
                Section {
                    NumberField(title: "Every", text: $intervalMiles, unit: "mi", keyboard: .numberPad)
                    NumberField(title: "Or every", text: $intervalMonths, unit: "months", keyboard: .numberPad)
                } header: {
                    Text("Interval")
                } footer: {
                    Text("Typical values — check your owner's manual.")
                }
                Section("Last done") {
                    Toggle("Recorded", isOn: $hasLast)
                    if hasLast {
                        DatePicker("Date", selection: $lastDate, displayedComponents: .date)
                        NumberField(title: "Odometer", text: $lastOdometer, unit: "mi", keyboard: .numberPad)
                    }
                    Button("Done Today", action: markDoneToday)
                }
            }
            .keyboardDoneButton()
            .navigationTitle(item == nil ? "New Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // Задача: быстро отметить «сделано сегодня» на текущем пробеге
    private func markDoneToday() {
        hasLast = true
        lastDate = .now
        lastOdometer = currentOdometer.map(String.init) ?? lastOdometer
    }

    // Задача: сохранить — обновить существующий норматив или создать новый
    private func save() {
        let target = item ?? MaintenanceItem(name: "", intervalMiles: nil, intervalMonths: nil)
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.intervalMiles = NumberInput.int(intervalMiles)
        target.intervalMonths = NumberInput.int(intervalMonths)
        target.lastDate = hasLast ? lastDate : nil
        target.lastOdometer = hasLast ? NumberInput.int(lastOdometer) : nil
        if item == nil { context.insert(target) }
        dismiss()
    }
}
