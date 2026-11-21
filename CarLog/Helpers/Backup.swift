import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// Задача: формат файла выгрузки — все записи приложения в одном JSON.
// Заправки ссылаются на заправку и марку бензина по номеру в списке, записи о работах — на работу по номеру.
// Версия 2: справочник работ и записи Maintenance. Старые файлы (версия 1) тоже читаются —
// из них берутся бензин, страховка и машина, а справочник работ заполняется стартовым набором
struct Backup: Codable {
    var version = 2
    var exportedAt = Date.now
    var car: CarDTO?
    var stations: [StationDTO] = []
    var grades: [String] = []
    var fuel: [FuelDTO] = []
    var insurance: [InsuranceDTO] = []
    var services: [ServiceDTO]?
    var records: [RecordDTO]?

    var recordCount: Int {
        fuel.count + insurance.count + (records?.count ?? 0)
    }

    struct CarDTO: Codable { var manufacturer: String?; var make, model, vin, plate: String; var year: Int? }
    struct StationDTO: Codable { var name, address: String }
    struct FuelDTO: Codable {
        var date: Date; var odometer: Int?; var gallons, total: Double
        var station: Int?; var grade: Int?
    }
    struct InsuranceDTO: Codable { var datePaid, validUntil: Date; var amount: Double; var company: String }
    struct ServiceDTO: Codable { var name: String; var intervalMiles, intervalMonths: Int?; var note: String }
    struct RecordDTO: Codable {
        var service: Int?; var date: Date; var odometer: Int?
        var serviceCenter: String; var cost: Double; var note: String
    }
}

// Задача: выгрузка всех записей в JSON и загрузка обратно с полной заменой
enum BackupService {
    static var fileName: String {
        "CarLog \(Date.now.formatted(.iso8601.year().month().day()))"
    }

    static func export(from context: ModelContext) throws -> Data {
        let stations = try context.fetch(FetchDescriptor<Station>())
        let grades = try context.fetch(FetchDescriptor<FuelGrade>())
        var backup = Backup()
        backup.car = try context.fetch(FetchDescriptor<CarProfile>()).first.map {
            .init(manufacturer: $0.manufacturer, make: $0.make, model: $0.model, vin: $0.vin, plate: $0.plate, year: $0.year)
        }
        backup.stations = stations.map { .init(name: $0.name, address: $0.address) }
        backup.grades = grades.map(\.name)
        backup.fuel = try context.fetch(FetchDescriptor<FuelEntry>()).map { entry in
            .init(date: entry.date, odometer: entry.odometer, gallons: entry.gallons, total: entry.total,
                  station: entry.station.flatMap { s in stations.firstIndex { $0 === s } },
                  grade: entry.grade.flatMap { g in grades.firstIndex { $0 === g } })
        }
        backup.insurance = try context.fetch(FetchDescriptor<InsuranceEntry>()).map {
            .init(datePaid: $0.datePaid, validUntil: $0.validUntil, amount: $0.amount, company: $0.company)
        }
        let services = try context.fetch(FetchDescriptor<MaintenanceItem>())
        backup.services = services.map {
            .init(name: $0.name, intervalMiles: $0.intervalMiles, intervalMonths: $0.intervalMonths, note: $0.note)
        }
        backup.records = try context.fetch(FetchDescriptor<MaintenanceRecord>()).map { record in
            .init(service: record.service.flatMap { s in services.firstIndex { $0 === s } },
                  date: record.date, odometer: record.odometer,
                  serviceCenter: record.serviceCenter, cost: record.cost, note: record.note)
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
        try deleteAll(MaintenanceRecord.self, in: context)
        try deleteAll(MaintenanceItem.self, in: context)
        try deleteAll(CarProfile.self, in: context)

        let car = CarProfile()
        if let dto = backup.car {
            car.manufacturer = dto.manufacturer ?? ""; car.make = dto.make; car.model = dto.model; car.year = dto.year
            car.vin = dto.vin; car.plate = dto.plate
        }
        context.insert(car)

        let stations = backup.stations.map { Station(name: $0.name, address: $0.address) }
        let grades = backup.grades.map { FuelGrade(name: $0) }
        stations.forEach(context.insert)
        grades.forEach(context.insert)

        for dto in backup.fuel {
            context.insert(FuelEntry(date: dto.date, odometer: dto.odometer, gallons: dto.gallons, total: dto.total,
                                     station: dto.station.flatMap { stations.indices.contains($0) ? stations[$0] : nil },
                                     grade: dto.grade.flatMap { grades.indices.contains($0) ? grades[$0] : nil }))
        }
        for dto in backup.insurance {
            context.insert(InsuranceEntry(datePaid: dto.datePaid, validUntil: dto.validUntil,
                                          amount: dto.amount, company: dto.company))
        }
        // Справочник работ: из файла, а для старого файла без него — стартовый набор
        let services = (backup.services ?? MaintenanceItem.defaults.map {
            Backup.ServiceDTO(name: $0.name, intervalMiles: $0.miles, intervalMonths: $0.months, note: $0.note)
        }).map { MaintenanceItem(name: $0.name, intervalMiles: $0.intervalMiles, intervalMonths: $0.intervalMonths, note: $0.note) }
        services.forEach(context.insert)
        for dto in backup.records ?? [] {
            let record = MaintenanceRecord(service: nil, date: dto.date, odometer: dto.odometer,
                                           serviceCenter: dto.serviceCenter, cost: dto.cost, note: dto.note)
            context.insert(record)
            record.service = dto.service.flatMap { services.indices.contains($0) ? services[$0] : nil }
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
