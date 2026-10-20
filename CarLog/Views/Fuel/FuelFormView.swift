import SwiftUI
import SwiftData

// Задача: форма добавления и правки заправки; цена за галлон считается сама
struct FuelFormView: View {
    let entry: FuelEntry?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FuelEntry.date, order: .reverse) private var allEntries: [FuelEntry]

    @State private var date = Date.now
    @State private var odometer = ""
    @State private var gallons = ""
    @State private var total = ""
    @State private var station: Station?
    @State private var grade: FuelGrade?
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    NumberField(title: "Odometer", text: $odometer, unit: "mi", keyboard: .numberPad)
                }
                Section {
                    NumberField(title: "Gallons", text: $gallons, unit: "gal")
                    NumberField(title: "Total", text: $total, unit: "USD")
                    LabeledContent("Price/gal", value: pricePerGallon?.asPricePerGallon ?? "—")
                } footer: {
                    Text("Price per gallon is calculated from total and gallons.")
                }
                Section {
                    NavigationLink {
                        StationPickerView(selection: $station)
                    } label: {
                        LabeledContent("Station", value: station?.name ?? "None")
                    }
                    NavigationLink {
                        GradePickerView(selection: $grade)
                    } label: {
                        LabeledContent("Grade", value: grade?.name ?? "None")
                    }
                }
            }
            .navigationTitle(entry == nil ? "New Fill-up" : "Edit Fill-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
    }

    // Задача: цена за галлон = стоимость / объём
    private var pricePerGallon: Double? {
        guard let g = NumberInput.double(gallons), let t = NumberInput.double(total), g > 0 else { return nil }
        return t / g
    }

    private var isValid: Bool {
        (NumberInput.double(gallons) ?? 0) > 0 && (NumberInput.double(total) ?? 0) > 0
    }

    // Задача: заполнить форму — из записи при правке, из последней заправки при добавлении.
    // Флаг нужен, чтобы возврат из списка заправок не сбрасывал введённое
    private func load() {
        guard !didLoad else { return }
        didLoad = true
        if let entry {
            date = entry.date
            odometer = entry.odometer.map(String.init) ?? ""
            gallons = NumberInput.text(entry.gallons)
            total = NumberInput.text(entry.total)
            station = entry.station
            grade = entry.grade
        } else {
            station = allEntries.first?.station
            grade = allEntries.first?.grade
        }
    }

    // Задача: сохранить — обновить существующую запись или создать новую
    private func save() {
        guard let g = NumberInput.double(gallons), let t = NumberInput.double(total) else { return }
        let miles = NumberInput.int(odometer)
        if let entry {
            entry.date = date
            entry.odometer = miles
            entry.gallons = g
            entry.total = t
            entry.station = station
            entry.grade = grade
        } else {
            context.insert(FuelEntry(date: date, odometer: miles, gallons: g, total: t, station: station, grade: grade))
        }
        dismiss()
    }
}
