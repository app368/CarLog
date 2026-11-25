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

    // Задача: предупреждение при удалении — пропадут контакты, а оплаты останутся без компании
    private var deleteMessage: String {
        let count = pendingDelete?.entries.count ?? 0
        guard count > 0 else { return "Its contacts will be deleted." }
        return UsageText.deleteMessage(count: count, item: "payment")
    }
}

// Задача: карточка страховой компании — номер полиса из последней оплаты (только показ, можно скопировать),
// адрес (тап — на карту), сайт (браузер), телефоны: общий, Claims (24/7), Customer Service (тап — звонок),
// email (письмо), примечание и число платежей
struct InsuranceCompanyDetailView: View {
    let company: InsuranceCompany
    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                LabeledContent("Name", value: company.name)
                // Номер полиса правится в оплате; здесь он рядом с Claims — его первым спрашивают по телефону
                if !company.currentPolicyNumber.isEmpty {
                    LabeledContent("Policy number") {
                        Text(company.currentPolicyNumber)
                            .textSelection(.enabled)
                    }
                }
            }
            // Сначала два самых нужных номера — Customer Service и Claims, дальше остальное
            Section("Contacts") {
                PhoneRow(title: "Customer Service", phone: company.servicePhone)
                PhoneRow(title: "Claims (24/7)", phone: company.claimsPhone)
                AddressRow(address: company.address)
                WebsiteRow(website: company.website)
                PhoneRow(phone: company.phone)
                EmailRow(email: company.email)
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
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            InsuranceCompanyFormView(company: company)
        }
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
                }
                Section("Contacts") {
                    LabeledField(title: "Customer Service", text: $servicePhone, keyboard: .phonePad)
                    LabeledField(title: "Claims (24/7)", text: $claimsPhone, keyboard: .phonePad)
                    TextField("Address", text: $address, axis: .vertical)
                    LabeledField(title: "Website", text: $website, keyboard: .URL)
                    LabeledField(title: "Phone", text: $phone, keyboard: .phonePad)
                    LabeledField(title: "Email", text: $email, keyboard: .emailAddress)
                }
                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...8)
                        .clearButton(text: $notes)
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

// Задача: строка формы с подписью слева и полем справа — для телефонов, сайта, почты, номера полиса.
// Телефон (клавиатура phonePad) раскладывается по группам прямо при вводе: (503) 823-3333
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
                .phoneFormatting($text, isOn: keyboard == .phonePad)
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
