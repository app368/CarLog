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

// Задача: строка телефона в карточке — тап набирает номер
struct PhoneRow: View {
    let phone: String

    var body: some View {
        if let url = URL(string: "tel:" + phone.filter { $0.isNumber || $0 == "+" }), !phone.isEmpty {
            LabeledContent("Phone") {
                Link(phone, destination: url)
            }
        } else {
            LabeledContent("Phone", value: "—")
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

// Задача: ссылки для сайта и почты
enum ContactLinks {
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
