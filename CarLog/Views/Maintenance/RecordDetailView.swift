import SwiftUI

// Задача: карточка записи — работа, дата, пробег, сервисный центр, стоимость, примечание и кнопка Edit
struct RecordDetailView: View {
    let record: MaintenanceRecord
    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                LabeledContent("Service", value: record.service?.name ?? "Unknown service")
                LabeledContent("Date", value: record.date.formatted(date: .long, time: .omitted))
                LabeledContent("Odometer", value: record.odometer?.asMiles ?? "—")
                LabeledContent("Service center", value: record.centerName.isEmpty ? "—" : record.centerName)
                LabeledContent("Cost", value: record.cost.asMoney)
            }
            if !record.note.isEmpty {
                Section("Note") {
                    Text(record.note)
                }
            }
        }
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            RecordFormView(record: record, service: nil)
        }
    }
}
