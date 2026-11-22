import Foundation
import SwiftData

// Задача: справочник сервисных центров — название, адрес, сайт, телефон, email и примечание
@Model
final class ServiceCenter {
    var name: String
    var address: String = ""
    var phone: String = ""
    var website: String = ""
    var email: String = ""
    var notes: String = ""

    // При удалении центра визиты остаются, ссылка просто обнуляется
    @Relationship(deleteRule: .nullify, inverse: \Visit.center)
    var visits: [Visit] = []

    init(name: String, address: String = "", phone: String = "", website: String = "", email: String = "",
         notes: String = "") {
        self.name = name
        self.address = address
        self.phone = phone
        self.website = website
        self.email = email
        self.notes = notes
    }
}
