import SwiftUI
import SwiftData

// Задача: справочник экстренных служб — название и телефон; тап по номеру сразу звонит, тап по названию — карточка.
// Порядок ручной: Edit → перетаскивание. Внизу строка Insurance claims — номер Claims (24/7) из карточки страховой
struct EmergencyContactsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \EmergencyContact.order) private var contacts: [EmergencyContact]
    @Query(sort: \InsuranceEntry.datePaid, order: .reverse) private var payments: [InsuranceEntry]
    @Query private var insurers: [InsuranceCompany]
    @State private var isAdding = false
    @State private var pendingDelete: EmergencyContact?
    @State private var opened: EmergencyContact?
    @State private var openedInsurer: InsuranceCompany?

    var body: some View {
        List {
            Section {
                ForEach(contacts) { contact in
                    CallRow(title: contact.name, subtitle: nil, phone: contact.phone) { opened = contact }
                }
                .onDelete { offsets in pendingDelete = offsets.map { contacts[$0] }.first }
                .onMove(perform: move)
            }
            Section {
                if let insurer = currentInsurer {
                    CallRow(title: "Insurance claims", subtitle: insurer.name, phone: insurer.claimsPhone) {
                        openedInsurer = insurer
                    }
                } else {
                    CallRow(title: "Insurance claims", subtitle: nil, phone: "")
                }
            } footer: {
                Text("Claims (24/7) number from the insurance company card in Info → Insurance companies.")
            }
        }
        .navigationTitle("Emergency Contacts")
        .navigationDestination(item: $opened) { contact in
            EmergencyContactDetailView(contact: contact)
        }
        .navigationDestination(item: $openedInsurer) { insurer in
            InsuranceCompanyDetailView(company: insurer)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                EditButton()
                Button("Add", systemImage: "plus") { isAdding = true }
            }
        }
        .sheet(isPresented: $isAdding) {
            EmergencyContactFormView(contact: nil, nextOrder: (contacts.map(\.order).max() ?? -1) + 1)
        }
        .alert("Delete emergency contact?", isPresented: Binding(get: { pendingDelete != nil },
                                                                set: { if !$0 { pendingDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let pendingDelete { context.delete(pendingDelete) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("“\(pendingDelete?.name ?? "")” will be deleted.")
        }
        .overlay {
            if contacts.isEmpty {
                ContentUnavailableView("No emergency contacts", systemImage: "phone",
                                       description: Text("Tap + to add one."))
            }
        }
    }

    // Задача: страховая для строки Claims — компания последнего платежа, а без платежей — единственная в справочнике
    private var currentInsurer: InsuranceCompany? {
        payments.first?.insurer ?? (insurers.count == 1 ? insurers.first : nil)
    }

    // Задача: перетаскивание — новый порядок сохраняется номерами по порядку
    private func move(from source: IndexSet, to destination: Int) {
        var items = contacts
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.order = index
        }
    }
}

// Задача: строка с номером — название (и подпись) слева, номер справа. Это две отдельные кнопки:
// тап по номеру звонит, тап по названию или стрелке открывает карточку (onOpen)
struct CallRow: View {
    let title: String
    let subtitle: String?
    let phone: String
    var onOpen: (() -> Void)?

    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 12) {
            if let onOpen {
                Button(action: onOpen) { titleBlock }
                    .buttonStyle(.plain)
            } else {
                titleBlock
            }
            if let url = ContactLinks.phone(phone) {
                Button(phone) { openURL(url) }
                    .buttonStyle(.borderless)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .fixedSize()
            } else {
                Text("—")
                    .foregroundStyle(.secondary)
            }
            if let onOpen {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .onTapGesture(perform: onOpen)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// Задача: карточка экстренной службы — телефон (звонок), адрес (карта), сайт (браузер), email (письмо), примечание
struct EmergencyContactDetailView: View {
    let contact: EmergencyContact
    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                LabeledContent("Name", value: contact.name)
                PhoneRow(phone: contact.phone)
                AddressRow(address: contact.address)
                WebsiteRow(website: contact.website)
                EmailRow(email: contact.email)
            }
            Section("Notes") {
                Text(contact.notes.isEmpty ? "—" : contact.notes)
                    .foregroundStyle(contact.notes.isEmpty ? .secondary : .primary)
            }
        }
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            EmergencyContactFormView(contact: contact, nextOrder: contact.order)
        }
    }
}

// Задача: форма экстренной службы — обязательно только название
struct EmergencyContactFormView: View {
    let contact: EmergencyContact?
    let nextOrder: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var phone: String
    @State private var address: String
    @State private var website: String
    @State private var email: String
    @State private var notes: String

    init(contact: EmergencyContact?, nextOrder: Int) {
        self.contact = contact
        self.nextOrder = nextOrder
        _name = State(initialValue: contact?.name ?? "")
        _phone = State(initialValue: contact?.phone ?? "")
        _address = State(initialValue: contact?.address ?? "")
        _website = State(initialValue: contact?.website ?? "")
        _email = State(initialValue: contact?.email ?? "")
        _notes = State(initialValue: contact?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name, axis: .vertical)
                    LabeledField(title: "Phone", text: $phone, keyboard: .phonePad)
                    TextField("Address", text: $address, axis: .vertical)
                    LabeledField(title: "Website", text: $website, keyboard: .URL)
                    LabeledField(title: "Email", text: $email, keyboard: .emailAddress)
                }
                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...8)
                }
            }
            .keyboardDoneButton()
            .navigationTitle(contact == nil ? "New Contact" : "Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // Задача: сохранить — обновить запись или добавить новую в конец списка
    private func save() {
        let target = contact ?? EmergencyContact(name: "", order: nextOrder)
        if contact == nil { context.insert(target) }
        target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        target.phone = phone.trimmingCharacters(in: .whitespaces)
        target.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        target.website = website.trimmingCharacters(in: .whitespaces)
        target.email = email.trimmingCharacters(in: .whitespaces)
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        dismiss()
    }
}
