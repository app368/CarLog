import SwiftUI
import SwiftData

// Задача: справочник страховых компаний на вкладке Info — список, карточка, добавить, изменить, удалить
struct InsuranceCompaniesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \InsuranceCompany.name) private var companies: [InsuranceCompany]
    @State private var isAdding = false
    @State private var pendingDelete: InsuranceCompany?

    var body: some View {
        List {
            ForEach(companies) { company in
                NavigationLink {
                    InsuranceCompanyDetailView(company: company)
                } label: {
                    NameAddressRow(name: company.name, address: company.address)
                }
            }
            .onDelete { offsets in pendingDelete = offsets.map { companies[$0] }.first }
        }
        .navigationTitle("Insurance Companies")
        .toolbar {
            Button("Add", systemImage: "plus") { isAdding = true }
        }
        .sheet(isPresented: $isAdding) {
            InsuranceCompanyFormView(company: nil)
        }
        .alert("Delete insurance company?", isPresented: Binding(get: { pendingDelete != nil },
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
            if companies.isEmpty {
                ContentUnavailableView("No insurance companies", systemImage: "checkmark.shield",
                                       description: Text("Tap + to add one."))
            }
        }
    }

    // Задача: предупреждение при удалении — с контактами пропадут и сведения о полисе
    private var deleteMessage: String {
        let count = pendingDelete?.entries.count ?? 0
        guard count > 0 else { return "Its contacts and policy number will be deleted." }
        return UsageText.deleteMessage(count: count, item: "payment")
    }
}

// Задача: карточка страховой компании — номер полиса (можно скопировать), адрес (тап — на карту),
// сайт (браузер), телефоны: общий, Claims (24/7), Customer Service (тап — звонок), email (письмо),
// примечание и число платежей. Строки раздела Contacts можно переставить: кнопка ↑↓ включает перетаскивание
struct InsuranceCompanyDetailView: View {
    let company: InsuranceCompany
    @State private var isEditing = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        List {
            Section {
                LabeledContent("Name", value: company.name)
                LabeledContent("Policy number") {
                    Text(company.policyNumber.isEmpty ? "—" : company.policyNumber)
                        .textSelection(.enabled)
                }
            }
            Section {
                ForEach(company.orderedContactFields, id: \.self) { field in
                    contactRow(field)
                }
                .onMove(perform: moveContacts)
            } header: {
                Text("Contacts")
            } footer: {
                if editMode.isEditing {
                    Text("Drag the rows into the order you need. Tap Done when finished.")
                }
            }
            Section("Notes") {
                Text(company.notes.isEmpty ? "—" : company.notes)
                    .foregroundStyle(company.notes.isEmpty ? .secondary : .primary)
            }
            Section {
                LabeledContent("Payments", value: "\(company.entries.count)")
            }
        }
        .navigationTitle(company.name)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            if editMode.isEditing {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { withAnimation { editMode = .inactive } }
                }
            } else {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Reorder contacts", systemImage: "arrow.up.arrow.down") {
                        withAnimation { editMode = .active }
                    }
                    Button("Edit") { isEditing = true }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            InsuranceCompanyFormView(company: company)
        }
    }

    // Задача: строка раздела Contacts по названию поля
    @ViewBuilder
    private func contactRow(_ field: InsuranceContactField) -> some View {
        switch field {
        case .address: AddressRow(address: company.address)
        case .website: WebsiteRow(website: company.website)
        case .phone: PhoneRow(phone: company.phone)
        case .claims: PhoneRow(title: "Claims (24/7)", phone: company.claimsPhone)
        case .service: PhoneRow(title: "Customer Service", phone: company.servicePhone)
        case .email: EmailRow(email: company.email)
        }
    }

    // Задача: сохранить новый порядок строк в компании
    private func moveContacts(from source: IndexSet, to destination: Int) {
        var fields = company.orderedContactFields
        fields.move(fromOffsets: source, toOffset: destination)
        company.contactOrder = fields.map(\.rawValue)
    }
}

// Задача: форма страховой компании. У полей с подписью слева подпись видна и после ввода —
// иначе три телефона не отличить друг от друга
struct InsuranceCompanyFormView: View {
    let company: InsuranceCompany?
    var onCreate: (InsuranceCompany) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var policyNumber: String
    @State private var address: String
    @State private var website: String
    @State private var phone: String
    @State private var claimsPhone: String
    @State private var servicePhone: String
    @State private var email: String
    @State private var notes: String

    init(company: InsuranceCompany?, onCreate: @escaping (InsuranceCompany) -> Void = { _ in }) {
        self.company = company
        self.onCreate = onCreate
        _name = State(initialValue: company?.name ?? "")
        _policyNumber = State(initialValue: company?.policyNumber ?? "")
        _address = State(initialValue: company?.address ?? "")
        _website = State(initialValue: company?.website ?? "")
        _phone = State(initialValue: company?.phone ?? "")
        _claimsPhone = State(initialValue: company?.claimsPhone ?? "")
        _servicePhone = State(initialValue: company?.servicePhone ?? "")
        _email = State(initialValue: company?.email ?? "")
        _notes = State(initialValue: company?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    LabeledField(title: "Policy number", text: $policyNumber, capitalization: .characters)
                }
                Section("Contacts") {
                    TextField("Address", text: $address, axis: .vertical)
                    LabeledField(title: "Website", text: $website, keyboard: .URL)
                    LabeledField(title: "Phone", text: $phone, keyboard: .phonePad)
                    LabeledField(title: "Claims (24/7)", text: $claimsPhone, keyboard: .phonePad)
                    LabeledField(title: "Customer Service", text: $servicePhone, keyboard: .phonePad)
                    LabeledField(title: "Email", text: $email, keyboard: .emailAddress)
                }
                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...8)
                }
            }
            .keyboardDoneButton()
            .navigationTitle(company == nil ? "New Company" : "Edit Company")
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

    // Задача: сохранить — обновить компанию или создать новую
    private func save() {
        let target = company ?? InsuranceCompany(name: "")
        if company == nil { context.insert(target) }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.policyNumber = policyNumber.trimmingCharacters(in: .whitespaces)
        target.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        target.website = website.trimmingCharacters(in: .whitespaces)
        target.phone = phone.trimmingCharacters(in: .whitespaces)
        target.claimsPhone = claimsPhone.trimmingCharacters(in: .whitespaces)
        target.servicePhone = servicePhone.trimmingCharacters(in: .whitespaces)
        target.email = email.trimmingCharacters(in: .whitespaces)
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if company == nil { onCreate(target) }
        dismiss()
    }
}

// Задача: строка формы с подписью слева и полем справа — для телефонов, сайта, почты, номера полиса
struct LabeledField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .never

    var body: some View {
        LabeledContent(title) {
            TextField("Optional", text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
                .multilineTextAlignment(.trailing)
        }
    }
}

// Задача: выбор страховой компании в форме платежа — тап выбирает, «+» добавляет новую и сразу выбирает её
struct InsuranceCompanyPickerView: View {
    @Binding var selection: InsuranceCompany?

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \InsuranceCompany.name) private var companies: [InsuranceCompany]
    @State private var isAdding = false

    var body: some View {
        List {
            ForEach(companies) { company in
                Button {
                    selection = company
                    dismiss()
                } label: {
                    HStack {
                        NameAddressRow(name: company.name, address: company.address)
                            .foregroundStyle(.primary)
                        Spacer()
                        if company == selection {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Insurance Companies")
        .toolbar {
            Button("Add", systemImage: "plus") { isAdding = true }
        }
        .sheet(isPresented: $isAdding) {
            InsuranceCompanyFormView(company: nil) { selection = $0 }
        }
        .overlay {
            if companies.isEmpty {
                ContentUnavailableView("No insurance companies", systemImage: "checkmark.shield",
                                       description: Text("Tap + to add one."))
            }
        }
    }
}
