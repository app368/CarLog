import SwiftUI
import SwiftData

// Задача: форма записи — работа из справочника (обязательно), дата, пробег, сервисный центр, стоимость, примечание.
// Сервисный центр выбирается из справочника и подставляется из прошлой записи;
// из карточки работы форма открывается с уже выбранной работой
struct RecordFormView: View {
    let record: MaintenanceRecord?
    let service: MaintenanceItem?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MaintenanceItem.name) private var items: [MaintenanceItem]
    @Query(sort: \MaintenanceRecord.date, order: .reverse) private var allRecords: [MaintenanceRecord]

    @State private var selected: MaintenanceItem?
    @State private var date = Date.now
    @State private var odometer = ""
    @State private var center: ServiceCenter?
    @State private var cost = ""
    @State private var note = ""
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Service", selection: $selected) {
                        Text("Choose").tag(nil as MaintenanceItem?)
                        ForEach(items) { item in
                            Text(item.name).tag(item as MaintenanceItem?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    NumberField(title: "Odometer", text: $odometer, unit: "mi", keyboard: .numberPad)
                }
                Section {
                    NavigationLink {
                        ServiceCenterPickerView(selection: $center)
                    } label: {
                        LabeledContent("Service center", value: center?.name ?? "None")
                    }
                    NumberField(title: "Cost", text: $cost, unit: "USD")
                }
                Section("Note") {
                    TextField("Optional", text: $note, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .keyboardDoneButton()
            .navigationTitle(record == nil ? "New Record" : "Edit Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(selected == nil)
                }
            }
            .onAppear(perform: load)
        }
    }

    // Задача: заполнить форму — из записи при правке; при добавлении — работа из карточки и сервисный центр из прошлой записи
    private func load() {
        guard !didLoad else { return }
        didLoad = true
        if let record {
            selected = record.service
            date = record.date
            odometer = record.odometer.map(String.init) ?? ""
            center = record.center
            cost = record.cost == 0 ? "" : NumberInput.text(record.cost)
            note = record.note
        } else {
            selected = service
            center = allRecords.first?.center
        }
    }

    // Задача: сохранить — обновить запись или создать новую; график пересчитается сам
    private func save() {
        let target = record ?? MaintenanceRecord(service: nil, center: nil, date: date, odometer: nil, cost: 0, note: "")
        if record == nil { context.insert(target) }
        target.service = selected
        target.date = date
        target.odometer = NumberInput.int(odometer)
        target.center = center
        target.cost = NumberInput.double(cost) ?? 0
        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        dismiss()
    }
}
