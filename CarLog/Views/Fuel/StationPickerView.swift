import SwiftUI
import SwiftData

// Задача: список заправок — выбор тапом, добавление «+», правка и удаление свайпом
struct StationPickerView: View {
    @Binding var selection: Station?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Station.name) private var stations: [Station]
    @State private var isAdding = false
    @State private var editing: Station?

    var body: some View {
        List {
            ForEach(stations) { station in
                Button {
                    selection = station
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(station.name)
                                .foregroundStyle(.primary)
                            if !station.address.isEmpty {
                                Text(station.address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if station == selection {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .swipeActions {
                    Button("Delete", role: .destructive) { delete(station) }
                    Button("Edit") { editing = station }
                        .tint(.orange)
                }
            }
        }
        .overlay {
            if stations.isEmpty {
                ContentUnavailableView("No stations", systemImage: "mappin.and.ellipse",
                                       description: Text("Tap + to add a gas station."))
            }
        }
        .navigationTitle("Stations")
        .toolbar {
            Button("Add", systemImage: "plus") { isAdding = true }
        }
        .sheet(isPresented: $isAdding) {
            StationFormView(station: nil) { selection = $0 }
        }
        .sheet(item: $editing) {
            StationFormView(station: $0)
        }
    }

    // Задача: удалить заправку; если она была выбрана — снять выбор
    private func delete(_ station: Station) {
        if station == selection { selection = nil }
        context.delete(station)
    }
}

// Задача: форма заправки — название и адрес
struct StationFormView: View {
    let station: Station?
    var onCreate: (Station) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var address: String

    init(station: Station?, onCreate: @escaping (Station) -> Void = { _ in }) {
        self.station = station
        self.onCreate = onCreate
        _name = State(initialValue: station?.name ?? "")
        _address = State(initialValue: station?.address ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Address", text: $address, axis: .vertical)
            }
            .navigationTitle(station == nil ? "New Station" : "Edit Station")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if let station {
            station.name = cleanName
            station.address = cleanAddress
        } else {
            let new = Station(name: cleanName, address: cleanAddress)
            context.insert(new)
            onCreate(new)
        }
        dismiss()
    }
}
