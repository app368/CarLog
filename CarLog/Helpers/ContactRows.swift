import SwiftUI

// Задача: строка адреса в карточке — тап открывает меню: показать адрес в Apple Maps или Google Maps
struct AddressRow: View {
    let address: String

    var body: some View {
        if address.isEmpty {
            LabeledContent("Address", value: "—")
        } else {
            Menu {
                if let url = MapLinks.apple(address) {
                    Link("Open in Apple Maps", destination: url)
                }
                if let url = MapLinks.google(address) {
                    Link("Open in Google Maps", destination: url)
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Address")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(address)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
}

// Задача: строка телефона в карточке — тап набирает номер; подпись можно задать (Phone, Claims и др.)
struct PhoneRow: View {
    var title = "Phone"
    let phone: String

    var body: some View {
        if let url = ContactLinks.phone(phone) {
            LabeledContent(title) {
                Link(PhoneFormat.format(phone), destination: url)
            }
        } else {
            LabeledContent(title, value: "—")
        }
    }
}

// Задача: строка сайта в карточке — тап открывает сайт в браузере; адрес без https:// дополняется
struct WebsiteRow: View {
    let website: String

    var body: some View {
        if let url = ContactLinks.website(website) {
            LabeledContent("Website") {
                Link(website, destination: url)
                    .lineLimit(1)
            }
        } else {
            LabeledContent("Website", value: "—")
        }
    }
}

// Задача: строка email в карточке — тап создаёт новое письмо в почте
struct EmailRow: View {
    let email: String

    var body: some View {
        if let url = ContactLinks.email(email) {
            LabeledContent("Email") {
                Link(email, destination: url)
                    .lineLimit(1)
            }
        } else {
            LabeledContent("Email", value: "—")
        }
    }
}

// Задача: ссылки для телефона, сайта и почты
enum ContactLinks {
    // В ссылке остаются только цифры и «+»; номера со звёздочкой (*677) iOS по ссылке не набирает
    static func phone(_ text: String) -> URL? {
        let digits = text.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty, !text.contains("*") else { return nil }
        return URL(string: "tel:" + digits)
    }

    static func website(_ text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let full = trimmed.lowercased().hasPrefix("http") ? trimmed : "https://" + trimmed
        return URL(string: full)
    }

    static func email(_ text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("@") else { return nil }
        return URL(string: "mailto:" + trimmed)
    }
}

// Задача: ссылки на карты по адресу. Google Maps откроется в приложении, если оно установлено, иначе в браузере
enum MapLinks {
    static func apple(_ address: String) -> URL? {
        query(address).flatMap { URL(string: "https://maps.apple.com/?q=\($0)") }
    }

    static func google(_ address: String) -> URL? {
        query(address).flatMap { URL(string: "https://www.google.com/maps/search/?api=1&query=\($0)") }
    }

    private static func query(_ address: String) -> String? {
        address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+?")))
    }
}
