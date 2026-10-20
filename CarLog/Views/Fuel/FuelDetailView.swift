import SwiftUI

// Задача: карточка заправки — все поля записи и кнопка Edit
struct FuelDetailView: View {
    let entry: FuelEntry
    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: entry.date.formatted(date: .long, time: .omitted))
                LabeledContent("Odometer", value: entry.odometer?.asMiles ?? "—")
            }
            Section {
                LabeledContent("Gallons", value: entry.gallons.asGallons)
                LabeledContent("Total", value: entry.total.asMoney)
                LabeledContent("Price/gal", value: entry.pricePerGallon.asPricePerGallon)
                LabeledContent("Grade", value: entry.grade?.name ?? "—")
            }
            Section("Station") {
                if let station = entry.station {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(station.name)
                        if !station.address.isEmpty {
                            Text(station.address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("—")
                }
            }
        }
        .navigationTitle("Fill-up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            FuelFormView(entry: entry)
        }
    }
}
