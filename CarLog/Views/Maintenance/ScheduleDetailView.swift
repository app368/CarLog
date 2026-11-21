import SwiftUI
import SwiftData

// Задача: карточка работы из графика — норматив, примечание, Last и Next с пробегом,
// все записи по этой работе и кнопка Add Record
struct ScheduleDetailView: View {
    let item: MaintenanceItem

    @Query private var fuel: [FuelEntry]
    @Query private var records: [MaintenanceRecord]
    @State private var isAdding = false

    var body: some View {
        let readings = Mileage.readings(fuel: fuel, records: records)
        let line = MaintenancePlan.line(for: item, currentMiles: Mileage.current(readings)?.miles,
                                        milesPerDay: Mileage.perDay(readings))
        List {
            Section {
                LabeledContent("Interval", value: item.intervalText)
                LabeledContent("Status") {
                    Text(line.status.label).foregroundStyle(line.status.color)
                }
                LabeledContent("Last", value: lastText(line))
                LabeledContent("Next", value: nextText(line))
            }
            if !item.note.isEmpty {
                Section("Note") {
                    Text(item.note)
                }
            }
            Section("Records") {
                if item.records.isEmpty {
                    Text("No records yet")
                        .foregroundStyle(.secondary)
                }
                ForEach(item.records.sorted { $0.date > $1.date }) { record in
                    NavigationLink {
                        RecordDetailView(record: record)
                    } label: {
                        ServiceRecordRow(record: record)
                    }
                }
                Button("Add Record", systemImage: "plus") { isAdding = true }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAdding) {
            RecordFormView(record: nil, service: item)
        }
    }

    // Задача: последняя работа — дата и пробег (в строке графика пробега нет, он здесь)
    private func lastText(_ line: ScheduleLine) -> String {
        guard let last = line.last else { return "—" }
        let date = last.date.formatted(date: .abbreviated, time: .omitted)
        return last.odometer.map { "\(date) · \($0.asMiles)" } ?? date
    }

    // Задача: следующая работа — ориентировочная дата и пробег
    private func nextText(_ line: ScheduleLine) -> String {
        let parts = [line.nextDate == nil ? nil : line.nextText, line.nextMiles?.asMiles].compactMap { $0 }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }
}

// Задача: запись в карточке работы — название работы и так известно, поэтому дата и стоимость, ниже сервисный центр
struct ServiceRecordRow: View {
    let record: MaintenanceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.date, format: .dateTime.month(.abbreviated).day().year())
                Spacer()
                Text(record.cost.asMoney)
            }
            Text(record.centerName.isEmpty ? "—" : record.centerName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
