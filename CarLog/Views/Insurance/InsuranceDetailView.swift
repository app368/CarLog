import SwiftUI

// Задача: карточка оплаты страховки и кнопка Edit
struct InsuranceDetailView: View {
    let entry: InsuranceEntry
    @State private var isEditing = false

    var body: some View {
        List {
            LabeledContent("Company", value: entry.company.isEmpty ? "—" : entry.company)
            LabeledContent("Amount", value: entry.amount.asMoney)
            LabeledContent("Paid", value: entry.datePaid.formatted(date: .long, time: .omitted))
            LabeledContent("Valid until", value: entry.validUntil.formatted(date: .long, time: .omitted))
        }
        .navigationTitle("Insurance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            InsuranceFormView(entry: entry)
        }
    }
}
