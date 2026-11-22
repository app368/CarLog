import SwiftUI
import SwiftData

// Задача: форма шапки визита — дата, сервисный центр, пробег, примечание.
// Центр выбирается из справочника и подставляется из прошлого визита
struct VisitFormView: View {
    let visit: Visit?
    var onCreate: (Visit) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Visit.date, order: .reverse) private var visits: [Visit]

    @State private var date = Date.now
    @State private var center: ServiceCenter?
    @State private var odometer = ""
    @State private var note = ""
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    NavigationLink {
                        ServiceCenterPickerView(selection: $center)
                    } label: {
                        LabeledContent("Service center", value: center?.name ?? "None")
                    }
                    NumberField(title: "Odometer", text: $odometer, unit: "mi", keyboard: .numberPad)
                }
                Section("Note") {
                    TextField("Optional", text: $note, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .keyboardDoneButton()
            .navigationTitle(visit == nil ? "New Visit" : "Edit Visit")
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

    // Задача: заполнить форму — из визита при правке; при добавлении — центр из прошлого визита
    private func load() {
        guard !didLoad else { return }
        didLoad = true
        if let visit {
            date = visit.date
            center = visit.center
            odometer = visit.odometer.map(String.init) ?? ""
            note = visit.note
        } else {
            center = visits.first?.center
        }
    }

    // Задача: сохранить — обновить визит или создать новый и открыть его карточку
    private func save() {
        let target = visit ?? Visit(date: date, odometer: nil, center: nil)
        if visit == nil { context.insert(target) }
        target.date = date
        target.center = center
        target.odometer = NumberInput.int(odometer)
        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if visit == nil { onCreate(target) }
        dismiss()
    }
}
