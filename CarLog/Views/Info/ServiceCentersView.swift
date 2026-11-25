import SwiftUI
import SwiftData

// Задача: справочник сервисных центров на вкладке Info — список, карточка, добавить, изменить, удалить
struct ServiceCentersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ServiceCenter.name) private var centers: [ServiceCenter]
    @State private var isAdding = false
    @State private var pendingDelete: ServiceCenter?

    var body: some View {
        List {
            ForEach(centers) { center in
                NavigationLink {
                    ServiceCenterDetailView(center: center)
                } label: {
                    NameAddressRow(name: center.name, address: center.address)
                }
            }
            .onDelete(perform: requestDelete)
        }
        .navigationTitle("Service Centers")
        .toolbar {
            Button("Add", systemImage: "plus") { isAdding = true }
        }
        .sheet(isPresented: $isAdding) {
            ServiceCenterFormView(center: nil)
        }
        .alert("Delete service center?", isPresented: Binding(get: { pendingDelete != nil },
                                                              set: { if !$0 { pendingDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let pendingDelete { context.delete(pendingDelete) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text(UsageText.deleteMessage(count: pendingDelete?.visits.count ?? 0, item: "visit"))
        }
        .overlay {
            if centers.isEmpty {
                ContentUnavailableView("No service centers", systemImage: "wrench.and.screwdriver",
                                       description: Text("Tap + to add a service center."))
            }
        }
    }

    // Задача: удаление свайпом; если у центра уже есть визиты — сначала спросить
    private func requestDelete(at offsets: IndexSet) {
        guard let center = offsets.map({ centers[$0] }).first else { return }
        if center.visits.isEmpty {
            context.delete(center)
        } else {
            pendingDelete = center
        }
    }
}

// Задача: карточка сервисного центра — название, адрес (тап — на карту), сайт (тап — в браузер),
// телефон (тап — звонок), email (тап — новое письмо), примечание и число визитов
struct ServiceCenterDetailView: View {
    let center: ServiceCenter
    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                LabeledContent("Name", value: center.name)
                AddressRow(address: center.address)
                WebsiteRow(website: center.website)
                PhoneRow(phone: center.phone)
                EmailRow(email: center.email)
            }
            Section("Notes") {
                Text(center.notes.isEmpty ? "—" : center.notes)
                    .foregroundStyle(center.notes.isEmpty ? .secondary : .primary)
            }
            Section {
                LabeledContent("Visits", value: "\(center.visits.count)")
            }
        }
        .navigationTitle(center.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            ServiceCenterFormView(center: center)
        }
    }
}

// Задача: форма сервисного центра — название, адрес, сайт, телефон, email, примечание
struct ServiceCenterFormView: View {
    let center: ServiceCenter?
    var onCreate: (ServiceCenter) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var address: String
    @State private var phone: String
    @State private var website: String
    @State private var email: String
    @State private var notes: String

    init(center: ServiceCenter?, onCreate: @escaping (ServiceCenter) -> Void = { _ in }) {
        self.center = center
        self.onCreate = onCreate
        _name = State(initialValue: center?.name ?? "")
        _address = State(initialValue: center?.address ?? "")
        _phone = State(initialValue: center?.phone ?? "")
        _website = State(initialValue: center?.website ?? "")
        _email = State(initialValue: center?.email ?? "")
        _notes = State(initialValue: center?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Address", text: $address, axis: .vertical)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .phoneFormatting($phone)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                        .clearButton(text: $notes)
                }
            }
            .keyboardDoneButton()
            .navigationTitle(center == nil ? "New Service Center" : "Edit Service Center")
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

    // Задача: сохранить — обновить центр или создать новый
    private func save() {
        let target = center ?? ServiceCenter(name: "")
        if center == nil { context.insert(target) }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        target.phone = phone.trimmingCharacters(in: .whitespaces)
        target.website = website.trimmingCharacters(in: .whitespaces)
        target.email = email.trimmingCharacters(in: .whitespaces)
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if center == nil { onCreate(target) }
        dismiss()
    }
}

// Задача: выбор сервисного центра в форме визита — тап выбирает, «+» добавляет новый и сразу выбирает его
struct ServiceCenterPickerView: View {
    @Binding var selection: ServiceCenter?

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ServiceCenter.name) private var centers: [ServiceCenter]
    @State private var isAdding = false

    var body: some View {
        List {
            ForEach(centers) { center in
                Button {
                    selection = center
                    dismiss()
                } label: {
                    HStack {
                        NameAddressRow(name: center.name, address: center.address)
                            .foregroundStyle(.primary)
                        Spacer()
                        if center == selection {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Service Centers")
        .toolbar {
            Button("Add", systemImage: "plus") { isAdding = true }
        }
        .sheet(isPresented: $isAdding) {
            ServiceCenterFormView(center: nil) { selection = $0 }
        }
        .overlay {
            if centers.isEmpty {
                ContentUnavailableView("No service centers", systemImage: "wrench.and.screwdriver",
                                       description: Text("Tap + to add a service center."))
            }
        }
    }
}
