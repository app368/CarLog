import SwiftUI

// Задача: карточка регламентных работ и кнопка Edit
struct ServiceDetailView: View {
    let entry: ServiceEntry
    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: entry.date.formatted(date: .long, time: .omitted))
                LabeledContent("Odometer", value: entry.odometer?.asMiles ?? "—")
                LabeledContent("Amount", value: entry.amount.asMoney)
            }
            Section("Work done") {
                Text(entry.work.isEmpty ? "—" : entry.work)
            }
        }
        .navigationTitle("Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            ServiceFormView(entry: entry)
        }
    }
}
