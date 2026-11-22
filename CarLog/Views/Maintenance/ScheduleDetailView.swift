import SwiftUI
import SwiftData

// Задача: карточка работы из графика — норматив, статус, Last и Next с пробегом, группа работ,
// примечание и история: визиты, в которых делали эту работу. Работы добавляются через визит
struct ScheduleDetailView: View {
    let item: MaintenanceItem

    @Query private var fuel: [FuelEntry]
    @Query private var visits: [Visit]

    var body: some View {
        let readings = Mileage.readings(fuel: fuel, visits: visits)
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
                if let group = ServiceGroups.group(for: item.name) {
                    NavigationLink {
                        ServiceGroupDetailView(group: group)
                    } label: {
                        LabeledContent("Group", value: group.name)
                    }
                }
            }
            if !item.note.isEmpty {
                Section("Note") {
                    Text(item.note)
                }
            }
            Section("History") {
                if item.lines.isEmpty {
                    Text("Not done yet")
                        .foregroundStyle(.secondary)
                }
                ForEach(history) { line in
                    if let visit = line.visit {
                        NavigationLink {
                            VisitDetailView(visit: visit)
                        } label: {
                            ServiceHistoryRow(line: line, visit: visit)
                        }
                    }
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // Задача: строки визитов с этой работой, новые сверху
    private var history: [VisitLine] {
        item.lines.filter { $0.visit != nil }.sorted { $0.visit!.date > $1.visit!.date }
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

// Задача: визит в истории работы — дата и цена строки, ниже сервисный центр и строка документа.
// Если в строке несколько работ, цена общая на всю строку
struct ServiceHistoryRow: View {
    let line: VisitLine
    let visit: Visit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(visit.date, format: .dateTime.month(.abbreviated).day().year())
                Spacer()
                Text(line.price.asMoney)
            }
            Text([visit.centerName, line.services.count > 1 ? line.name : ""].filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
