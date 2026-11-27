import Foundation
import SwiftData

// Задача: документ — страница из сервиса в визите, страховая карточка в оплате страховки,
// регистрационная карточка в продлении регистрации или документ в Maintenance → Reference
// (например, готовые сообщения для мастера). Хранится отдельным файлом рядом с базой:
// снимок JPEG или файл PDF как есть (резкий при любом увеличении, Share отдаёт исходный файл)
@Model
final class DocumentPage {
    var visit: Visit?
    var insurance: InsuranceEntry?
    var registration: RegistrationEntry?
    // Документ из Reference — записи-владельца у него нет, поэтому он помечается отметкой
    var inReference: Bool = false
    // Название поля осталось со времён, когда документы были только снимками; в нём же лежит и PDF
    @Attribute(.externalStorage) var imageData: Data
    var isPDF: Bool = false
    var order: Int = 0

    init(imageData: Data, order: Int, isPDF: Bool = false) {
        self.imageData = imageData
        self.order = order
        self.isPDF = isPDF
    }
}
