import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// Задача: формат файла выгрузки — все записи приложения в одном JSON.
// Заправки ссылаются на заправку и марку бензина по номеру в списке,
// визиты — на сервисный центр по номеру, строки визитов — на работы по номерам.
// Версия 5: справочник страховых компаний; платежи ссылаются на компанию по номеру.
// Версия 4: визиты со строками и фото документов (фото — внутри файла, в виде base64).
// Версии 2 и 3 читаются — справочники берутся, старые записи о работах пропускаются.
// Версия 1 читается — из неё берутся бензин, страховка и машина, а справочник работ заполняется стартовым набором
struct Backup: Codable {
    var version = 5
    var exportedAt = Date.now
    var car: CarDTO?
    var stations: [StationDTO] = []
    var grades: [String] = []
    var fuel: [FuelDTO] = []
    var insurance: [InsuranceDTO] = []
    var insurers: [InsurerDTO]?
    var services: [ServiceDTO]?
    var centers: [CenterDTO]?
    var visits: [VisitDTO]?

    var recordCount: Int {
        fuel.count + insurance.count + (visits?.count ?? 0)
    }

    struct CarDTO: Codable { var manufacturer: String?; var make, model, vin, plate: String; var year: Int? }
    struct StationDTO: Codable { var name, address: String; var notes: String? }
    struct CenterDTO: Codable { var name, address, phone, notes: String; var website, email: String? }
    struct FuelDTO: Codable {
        var date: Date; var odometer: Int?; var gallons, total: Double
        var station: Int?; var grade: Int?
    }
    struct InsuranceDTO: Codable {
        var datePaid, validUntil: Date; var amount: Double; var company: String; var insurer: Int?
    }
    struct InsurerDTO: Codable {
        var name, policyNumber, address, website, phone, claimsPhone, servicePhone, email, notes: String
    }
    struct ServiceDTO: Codable { var name: String; var intervalMiles, intervalMonths: Int?; var note: String }
    struct VisitDTO: Codable {
        var date: Date; var odometer: Int?; var note: String; var center: Int?
        var lines: [LineDTO]; var pages: [Data]
    }
    struct LineDTO: Codable { var name: String; var price: Double; var services: [Int] }
}

// Задача: выгрузка всех записей в JSON и загрузка обратно с полной заменой
enum BackupService {
    static var fileName: String {
        "CarLog \(Date.now.fileDay)"
    }

    static func export(from context: ModelContext) throws -> Data {
        let stations = try context.fetch(FetchDescriptor<Station>())
        let grades = try context.fetch(FetchDescriptor<FuelGrade>())
        var backup = Backup()
        backup.car = try context.fetch(FetchDescriptor<CarProfile>()).first.map {
            .init(manufacturer: $0.manufacturer, make: $0.make, model: $0.model, vin: $0.vin, plate: $0.plate, year: $0.year)
        }
        backup.stations = stations.map { .init(name: $0.name, address: $0.address, notes: $0.notes) }
        backup.grades = grades.map(\.name)
        backup.fuel = try context.fetch(FetchDescriptor<FuelEntry>()).map { entry in
            .init(date: entry.date, odometer: entry.odometer, gallons: entry.gallons, total: entry.total,
                  station: entry.station.flatMap { s in stations.firstIndex { $0 === s } },
                  grade: entry.grade.flatMap { g in grades.firstIndex { $0 === g } })
        }
        let insurers = try context.fetch(FetchDescriptor<InsuranceCompany>())
        backup.insurers = insurers.map {
            .init(name: $0.name, policyNumber: $0.policyNumber, address: $0.address, website: $0.website, phone: $0.phone,
                  claimsPhone: $0.claimsPhone, servicePhone: $0.servicePhone, email: $0.email, notes: $0.notes)
        }
        backup.insurance = try context.fetch(FetchDescriptor<InsuranceEntry>()).map { entry in
            .init(datePaid: entry.datePaid, validUntil: entry.validUntil, amount: entry.amount, company: entry.company,
                  insurer: entry.insurer.flatMap { c in insurers.firstIndex { $0 === c } })
        }
        let services = try context.fetch(FetchDescriptor<MaintenanceItem>())
        backup.services = services.map {
            .init(name: $0.name, intervalMiles: $0.intervalMiles, intervalMonths: $0.intervalMonths, note: $0.note)
        }
        let centers = try context.fetch(FetchDescriptor<ServiceCenter>())
        backup.centers = centers.map {
            .init(name: $0.name, address: $0.address, phone: $0.phone, notes: $0.notes, website: $0.website, email: $0.email)
        }
        backup.visits = try context.fetch(FetchDescriptor<Visit>()).map { visit in
            .init(date: visit.date, odometer: visit.odometer, note: visit.note,
                  center: visit.center.flatMap { c in centers.firstIndex { $0 === c } },
                  lines: visit.sortedLines.map { line in
                      .init(name: line.name, price: line.price,
                            services: line.services.compactMap { s in services.firstIndex { $0 === s } })
                  },
                  pages: visit.sortedPages.map(\.imageData))
        }
        return try encoder.encode(backup)
    }

    // Задача: проверить файл до того, как что-то удалять
    static func decode(_ data: Data) throws -> Backup {
        try decoder.decode(Backup.self, from: data)
    }

    // Задача: удалить все текущие записи и создать записи из файла
    static func restore(_ backup: Backup, into context: ModelContext) throws {
        try deleteAll(FuelEntry.self, in: context)
        try deleteAll(Station.self, in: context)
        try deleteAll(FuelGrade.self, in: context)
        try deleteAll(InsuranceEntry.self, in: context)
        try deleteAll(InsuranceCompany.self, in: context)
        try deleteAll(Visit.self, in: context)
        try deleteAll(VisitLine.self, in: context)
        try deleteAll(DocumentPage.self, in: context)
        try deleteAll(MaintenanceItem.self, in: context)
        try deleteAll(ServiceCenter.self, in: context)
        try deleteAll(CarProfile.self, in: context)

        let car = CarProfile()
        if let dto = backup.car {
            car.manufacturer = dto.manufacturer ?? ""; car.make = dto.make; car.model = dto.model; car.year = dto.year
            car.vin = dto.vin; car.plate = dto.plate
        }
        context.insert(car)

        let stations = backup.stations.map { Station(name: $0.name, address: $0.address, notes: $0.notes ?? "") }
        let grades = backup.grades.map { FuelGrade(name: $0) }
        stations.forEach(context.insert)
        grades.forEach(context.insert)

        for dto in backup.fuel {
            context.insert(FuelEntry(date: dto.date, odometer: dto.odometer, gallons: dto.gallons, total: dto.total,
                                     station: dto.station.flatMap { stations.indices.contains($0) ? stations[$0] : nil },
                                     grade: dto.grade.flatMap { grades.indices.contains($0) ? grades[$0] : nil }))
        }
        // Справочник страховых компаний; в старых файлах (до версии 5) компания — текстом, её переносит миграция ниже
        let insurers = (backup.insurers ?? []).map { dto in
            let company = InsuranceCompany(name: dto.name)
            company.policyNumber = dto.policyNumber; company.address = dto.address; company.website = dto.website
            company.phone = dto.phone; company.claimsPhone = dto.claimsPhone; company.servicePhone = dto.servicePhone
            company.email = dto.email; company.notes = dto.notes
            return company
        }
        insurers.forEach(context.insert)
        for dto in backup.insurance {
            let entry = InsuranceEntry(datePaid: dto.datePaid, validUntil: dto.validUntil, amount: dto.amount, company: dto.company)
            context.insert(entry)
            entry.insurer = dto.insurer.flatMap { insurers.indices.contains($0) ? insurers[$0] : nil }
        }
        InsuranceEntry.migrateCompanyNames(in: context)
        // Справочник работ: из файла, а для старого файла без него — стартовый набор
        let services = (backup.services ?? MaintenanceItem.defaults.map {
            Backup.ServiceDTO(name: $0.name, intervalMiles: $0.miles, intervalMonths: $0.months, note: $0.note)
        }).map { MaintenanceItem(name: $0.name, intervalMiles: $0.intervalMiles, intervalMonths: $0.intervalMonths, note: $0.note) }
        services.forEach(context.insert)
        let centers = (backup.centers ?? []).map {
            ServiceCenter(name: $0.name, address: $0.address, phone: $0.phone, website: $0.website ?? "",
                          email: $0.email ?? "", notes: $0.notes)
        }
        centers.forEach(context.insert)
        for dto in backup.visits ?? [] {
            let visit = Visit(date: dto.date, odometer: dto.odometer, center: nil, note: dto.note)
            context.insert(visit)
            visit.center = dto.center.flatMap { centers.indices.contains($0) ? centers[$0] : nil }
            for (order, lineDTO) in dto.lines.enumerated() {
                let line = VisitLine(name: lineDTO.name, price: lineDTO.price, order: order)
                context.insert(line)
                line.visit = visit
                line.services = lineDTO.services.compactMap { services.indices.contains($0) ? services[$0] : nil }
            }
            for (order, data) in dto.pages.enumerated() {
                let page = DocumentPage(imageData: data, order: order)
                context.insert(page)
                page.visit = visit
            }
        }
        try context.save()
    }

    private static func deleteAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws {
        try context.fetch(FetchDescriptor<T>()).forEach(context.delete)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

// Задача: обёртка над данными выгрузки для системного окна сохранения файла
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
