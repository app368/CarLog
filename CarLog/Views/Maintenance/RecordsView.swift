import SwiftUI
import SwiftData

// Задача: экран Maintenance Records — выполненные работы, новые сверху; фильтр по дате визита
struct RecordsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MaintenanceRecord.date, order: .reverse) private var records: [MaintenanceRecord]
    @State private var filterDate: Date?
    @State private var isPickingDate = false
    @State private var isAdding = false

    var body: some View {
        List {
            if let filterDate {
                Section {
                    FilterSummary(date: filterDate, records: shown) { self.filterDate = nil }
                }
            }
            Section {
                ForEach(shown) { record in
                    NavigationLink {
                        RecordDetailView(record: record)
                    } label: {
                        RecordRow(record: record)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Filter by date", systemImage: "calendar") { isPickingDate = true }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") { isAdding = true }
            }
        }
        .sheet(isPresented: $isAdding) {
            RecordFormView(record: nil, service: nil)
        }
        .sheet(isPresented: $isPickingDate) {
            DateFilterSheet(initial: filterDate ?? records.first?.date ?? .now) { filterDate = $0 }
        }
        .overlay {
            if records.isEmpty {
                ContentUnavailableView("No records yet", systemImage: "list.bullet.clipboard",
                                       description: Text("Tap + to add a completed service."))
            } else if shown.isEmpty {
                ContentUnavailableView("No records on this date", systemImage: "calendar")
            }
        }
    }

    // Задача: записи с учётом фильтра — все или только за выбранный день
    private var shown: [MaintenanceRecord] {
        guard let filterDate else { return records }
        return records.filter { Calendar.current.isDate($0.date, inSameDayAs: filterDate) }
    }

    // Задача: удаление свайпом
    private func delete(at offsets: IndexSet) {
        offsets.map { shown[$0] }.forEach(context.delete)
    }
}

// Задача: строка записи — работа и дата, ниже сервисный центр и стоимость
struct RecordRow: View {
    let record: MaintenanceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.service?.name ?? "Unknown service")
                Spacer()
                Text(record.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.subheadline)
            }
            HStack {
                Text(record.centerName.isEmpty ? "—" : record.centerName)
                Spacer()
                Text(record.cost.asMoney)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

// Задача: строка-итог фильтра — дата, сервисный центр, число записей, сумма и кнопка сброса
private struct FilterSummary: View {
    let date: Date
    let records: [MaintenanceRecord]
    let onClear: () -> Void

    var body: some View {
        HStack {
            Text(summary)
                .font(.subheadline)
            Spacer()
            Button("Clear filter", systemImage: "xmark.circle.fill", action: onClear)
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
        }
    }

    private var summary: String {
        let centers = Set(records.map(\.centerName).filter { !$0.isEmpty })
        var parts = [date.formatted(date: .abbreviated, time: .omitted)]
        if centers.count == 1, let center = centers.first {
            parts.append(center)
        } else if centers.count > 1 {
            parts.append("\(centers.count) service centers")
        }
        parts.append(records.count == 1 ? "1 record" : "\(records.count) records")
        parts.append(records.reduce(0) { $0 + $1.cost }.asMoney)
        return parts.joined(separator: " · ")
    }
}

// Задача: выбор даты для фильтра — календарь
private struct DateFilterSheet: View {
    let onPick: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date: Date

    init(initial: Date, onPick: @escaping (Date) -> Void) {
        self.onPick = onPick
        _date = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Visit Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Show") {
                            onPick(date)
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}
