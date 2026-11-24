import SwiftUI
import SwiftData

// Задача: руководство «Что делать при ДТП» — чек-лист: строка по-английски, под ней по-русски, слева птичка.
// Номера звонков берутся из справочника экстренных служб и карточки страховой, данные о себе — из приложения.
// Отметки сохраняются, пока не нажата Start over, — можно уйти позвонить и вернуться
struct AccidentGuideView: View {
    @Query(sort: \EmergencyContact.order) private var contacts: [EmergencyContact]
    @Query private var payments: [InsuranceEntry]
    @Query private var insurers: [InsuranceCompany]
    @Query private var profiles: [CarProfile]
    @AppStorage("accidentGuideChecked") private var checkedRaw = ""
    @State private var isConfirmingReset = false

    var body: some View {
        List {
            ForEach(AccidentGuide.sections) { section in
                Section {
                    ForEach(section.items) { item in
                        GuideRow(id: item.id, en: englishText(item), ru: item.ru, isWarning: section.isWarning,
                                 isChecked: checked.contains(item.id), phone: phone(for: item),
                                 link: link(for: item)) { toggle(item.id) }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(section.id). \(section.en)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(section.ru)
                            .font(.subheadline)
                    }
                    .textCase(nil)
                }
            }
            Section {
            } footer: {
                Text(AccidentGuide.source)
            }
        }
        .navigationTitle("Accident Guide")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Start over") { isConfirmingReset = true }
                .disabled(checked.isEmpty)
        }
        .confirmationDialog("Clear all checkmarks?", isPresented: $isConfirmingReset, titleVisibility: .visible) {
            Button("Clear Checkmarks", role: .destructive) { checkedRaw = "" }
        }
    }

    // Задача: отмеченные пункты — хранятся строкой «1.1,2.3» в настройках приложения
    private var checked: Set<String> {
        Set(checkedRaw.split(separator: ",").map(String.init))
    }

    private func toggle(_ id: String) {
        var set = checked
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        checkedRaw = set.sorted().joined(separator: ",")
    }

    private var insurer: InsuranceCompany? {
        InsuranceCompany.current(payments: payments, companies: insurers)
    }

    private func contact(_ role: String) -> EmergencyContact? {
        contacts.first { $0.role == role }
    }

    // Задача: английская строка; у пунктов «Ваши данные» — подставленные из приложения страховая и машина
    private func englishText(_ item: GuideItem) -> String {
        switch item.action {
        case .yourInsurance:
            guard let insurer else { return "Insurance: not set — add it in Info → Insurance companies." }
            // Номер полиса — из последней оплаты этой компании
            let number = insurer.currentPolicyNumber
            let policy = number.isEmpty ? "policy number not set" : "policy \(number)"
            return "Insurance: \(insurer.name) · \(policy)"
        case .yourCar:
            let car = profiles.first
            let name = [car?.year.map(String.init), car?.make, car?.model]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
            let plate = (car?.plate.isEmpty ?? true) ? "plate not set" : "plate \(car!.plate)"
            return "Car: \(name.isEmpty ? "not set" : name) · \(plate)"
        default:
            return item.en
        }
    }

    // Задача: номер для кнопки звонка справа
    private func phone(for item: GuideItem) -> String? {
        switch item.action {
        case .call(let role): contact(role)?.phone
        case .claims: insurer?.claimsPhone
        case .dmvReport: contact("dmv")?.phone
        default: nil
        }
    }

    // Задача: ссылка под строкой — отчёт о ДТП на сайте DMV
    private func link(for item: GuideItem) -> URL? {
        guard case .dmvReport = item.action else { return nil }
        return ContactLinks.website(contact("dmv")?.website ?? "")
            ?? URL(string: "https://www.oregon.gov/odot/DMV/pages/driverid/accidentreport.aspx")
    }
}

// Задача: строка чек-листа — птичка (или ⚠ в разделе Don't), номер и текст на двух языках во всю ширину,
// под ними кнопка звонка и ссылка. Тап по тексту ставит или снимает птичку; тап по номеру звонит
private struct GuideRow: View {
    let id: String
    let en: String
    let ru: String
    let isWarning: Bool
    let isChecked: Bool
    let phone: String?
    let link: URL?
    let onToggle: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isWarning {
                content
            } else {
                Button(action: onToggle) { content }
                    .buttonStyle(.plain)
            }
            if callURL != nil || link != nil {
                // Кнопки одна под другой — номер всегда в одну строку
                VStack(alignment: .leading, spacing: 8) { buttons }
                .buttonStyle(.borderless)
                .font(.subheadline.weight(.semibold))
                .padding(.leading, 34)
            }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        if let phone, let url = callURL {
            Button(PhoneFormat.format(phone), systemImage: "phone.fill") { openURL(url) }
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
        }
        if let link {
            Button("Report online", systemImage: "safari") { openURL(link) }
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
        }
    }

    private var callURL: URL? {
        phone.flatMap(ContactLinks.phone)
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(id)  \(en)")
                    .fixedSize(horizontal: false, vertical: true)
                Text(ru)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }

    private var icon: String {
        if isWarning { return "exclamationmark.triangle.fill" }
        return isChecked ? "checkmark.circle.fill" : "circle"
    }

    private var iconColor: Color {
        if isWarning { return Color("StatusSoon") }
        return isChecked ? .accentColor : .secondary
    }
}
