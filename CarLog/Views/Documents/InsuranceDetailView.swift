import SwiftUI

// Задача: карточка оплаты страховки и кнопка Edit; тап по компании открывает её карточку с контактами
struct InsuranceDetailView: View {
    let entry: InsuranceEntry
    @State private var isEditing = false

    var body: some View {
        List {
            if let insurer = entry.insurer {
                NavigationLink {
                    InsuranceCompanyDetailView(company: insurer)
                } label: {
                    LabeledContent("Company", value: insurer.name)
                }
            } else {
                LabeledContent("Company", value: entry.companyName.isEmpty ? "—" : entry.companyName)
            }
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
