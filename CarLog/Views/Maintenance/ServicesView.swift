import SwiftUI
import SwiftData

// Задача: экран Maintenance Services — справочник работ: название и норматив, по алфавиту.
// Группы делаются через названия с общим префиксом — при сортировке они встают рядом
struct ServicesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MaintenanceItem.name) private var items: [MaintenanceItem]
    @State private var isAdding = false
    @State private var pendingDelete: MaintenanceItem?

    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink {
                    MaintenanceServiceDetailView(item: item)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                        Text(item.intervalText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: requestDelete)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") { isAdding = true }
            }
        }
        .sheet(isPresented: $isAdding) {
            MaintenanceServiceFormView(item: nil)
        }
        .alert("Delete service?", isPresented: Binding(get: { pendingDelete != nil },
                                                       set: { if !$0 { pendingDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let pendingDelete { context.delete(pendingDelete) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text(deleteMessage)
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("No services yet", systemImage: "wrench.and.screwdriver",
                                       description: Text("Tap + to add a service."))
            }
        }
    }

    // Задача: текст предупреждения с числом записей — «1 record» / «3 records»
    private var deleteMessage: String {
        let count = pendingDelete?.records.count ?? 0
        return count == 1
            ? "There is 1 record for this service. It will be deleted too."
            : "There are \(count) records for this service. They will be deleted too."
    }

    // Задача: удаление свайпом; если по работе есть записи — сначала спросить
    private func requestDelete(at offsets: IndexSet) {
        guard let item = offsets.map({ items[$0] }).first else { return }
        if item.records.isEmpty {
            context.delete(item)
        } else {
            pendingDelete = item
        }
    }
}

// Задача: карточка работы в справочнике — норматив, примечание и кнопка Edit
struct MaintenanceServiceDetailView: View {
    let item: MaintenanceItem
    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                LabeledContent("Interval", value: item.intervalText)
                LabeledContent("Records", value: "\(item.records.count)")
            }
            if !item.note.isEmpty {
                Section("Note") {
                    Text(item.note)
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            MaintenanceServiceFormView(item: item)
        }
    }
}

// Задача: форма работы — название, норматив (необязателен) и примечание
struct MaintenanceServiceFormView: View {
    let item: MaintenanceItem?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var intervalMiles: String
    @State private var intervalMonths: String
    @State private var note: String

    init(item: MaintenanceItem?) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _intervalMiles = State(initialValue: item?.intervalMiles.map(String.init) ?? "")
        _intervalMonths = State(initialValue: item?.intervalMonths.map(String.init) ?? "")
        _note = State(initialValue: item?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                } footer: {
                    Text("To group services, start names the same way, e.g. “Timing belt: Water pump”.")
                }
                Section {
                    NumberField(title: "Every", text: $intervalMiles, unit: "mi", keyboard: .numberPad)
                    NumberField(title: "Or every", text: $intervalMonths, unit: "months", keyboard: .numberPad)
                } header: {
                    Text("Interval")
                } footer: {
                    Text("Leave empty if the service has no schedule. If Maintenance Minder asks earlier, follow it.")
                }
                Section("Note") {
                    TextField("Optional", text: $note, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .keyboardDoneButton()
            .navigationTitle(item == nil ? "New Service" : "Edit Service")
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

    // Задача: сохранить — обновить работу или создать новую
    private func save() {
        let target = item ?? MaintenanceItem(name: "", intervalMiles: nil, intervalMonths: nil)
        if item == nil { context.insert(target) }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.intervalMiles = NumberInput.int(intervalMiles)
        target.intervalMonths = NumberInput.int(intervalMonths)
        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        dismiss()
    }
}
