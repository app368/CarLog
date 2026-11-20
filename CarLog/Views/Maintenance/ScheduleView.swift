import SwiftUI
import SwiftData

// Задача: экран Maintenance Schedule — график работ: Last, Next и статус, ближайшие сроки сверху
struct ScheduleView: View {
    @Query private var items: [MaintenanceItem]
    @Query private var fuel: [FuelEntry]
    @Query private var records: [MaintenanceRecord]

    var body: some View {
        let readings = Mileage.readings(fuel: fuel, records: records)
        let current = Mileage.current(readings)
        let lines = MaintenancePlan.lines(for: items, currentMiles: current?.miles,
                                          milesPerDay: Mileage.perDay(readings))
        List {
            Section {
                ForEach(lines) { line in
                    NavigationLink {
                        ScheduleDetailView(item: line.item)
                    } label: {
                        ScheduleRow(line: line)
                    }
                }
            } header: {
                if let current {
                    Text("Odometer: \(current.miles.asMiles) · \(current.date.formatted(.dateTime.month(.abbreviated).day()))")
                }
            }
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("No services yet", systemImage: "wrench.and.screwdriver",
                                       description: Text("Add services on the Services tab."))
            }
        }
    }
}

// Задача: строка графика — работа и статус, ниже Last и Next
struct ScheduleRow: View {
    let line: ScheduleLine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(line.item.name)
                Spacer()
                Text(line.status.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(line.status.color)
            }
            if let last = line.last {
                DateLine(title: "Last", value: last.date.formatted(date: .abbreviated, time: .omitted))
                DateLine(title: "Next", value: line.nextText)
            } else {
                Text("No record yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Задача: подпись «Last  Oct 30, 2025» с выровненным заголовком
private struct DateLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .frame(width: 36, alignment: .leading)
            Text(value)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

extension ScheduleLine {
    // Задача: следующий срок месяцем и годом; «≈» — если дата оценена по среднему пробегу
    var nextText: String {
        guard let nextDate else { return "—" }
        let text = nextDate.formatted(.dateTime.month(.abbreviated).year())
        return isEstimated ? "≈ \(text)" : text
    }
}

extension ScheduleStatus {
    // Задача: цвет статуса — зелёный, жёлтый, красный, серый
    var color: Color {
        switch self {
        case .ok: .green
        case .soon: Color("StatusSoon")
        case .overdue: .red
        case .noRecord, .noInterval, .unknown: .secondary
        }
    }
}
