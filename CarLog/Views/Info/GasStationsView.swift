import SwiftUI
import SwiftData

// Задача: справочник заправок на вкладке Info — список, карточка, добавить, изменить, удалить
struct GasStationsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Station.name) private var stations: [Station]
    @State private var isAdding = false
    @State private var pendingDelete: Station?

    var body: some View {
        List {
            ForEach(stations) { station in
                NavigationLink {
                    StationDetailView(station: station)
                } label: {
                    NameAddressRow(name: station.name, address: station.address)
                }
            }
            .onDelete(perform: requestDelete)
        }
        .navigationTitle("Gas Stations")
        .toolbar {
            Button("Add", systemImage: "plus") { isAdding = true }
        }
        .sheet(isPresented: $isAdding) {
            StationFormView(station: nil)
        }
        .alert("Delete station?", isPresented: Binding(get: { pendingDelete != nil },
                                                       set: { if !$0 { pendingDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let pendingDelete { context.delete(pendingDelete) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text(UsageText.deleteMessage(count: pendingDelete?.entries.count ?? 0, item: "fill-up"))
        }
        .overlay {
            if stations.isEmpty {
                ContentUnavailableView("No stations", systemImage: "fuelpump",
                                       description: Text("Tap + to add a gas station."))
            }
        }
    }

    // Задача: удаление свайпом; если на заправке уже заправлялись — сначала спросить
    private func requestDelete(at offsets: IndexSet) {
        guard let station = offsets.map({ stations[$0] }).first else { return }
        if station.entries.isEmpty {
            context.delete(station)
        } else {
            pendingDelete = station
        }
    }
}

// Задача: карточка заправки — название, адрес (тап — на карту), примечание, число заправок и кнопка Edit
struct StationDetailView: View {
    let station: Station
    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                LabeledContent("Name", value: station.name)
                AddressRow(address: station.address)
                LabeledContent("Fill-ups", value: "\(station.entries.count)")
            }
            if !station.notes.isEmpty {
                Section("Notes") {
                    Text(station.notes)
                }
            }
        }
        .navigationTitle(station.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            StationFormView(station: station)
        }
    }
}

// Задача: строка справочника — название, под ним адрес
struct NameAddressRow: View {
    let name: String
    let address: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
            if !address.isEmpty {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Задача: текст предупреждения при удалении элемента справочника, который уже используется
enum UsageText {
    static func deleteMessage(count: Int, item: String) -> String {
        let records = count == 1 ? "1 \(item)" : "\(count) \(item)s"
        return "It is used in \(records). They will stay, without this name."
    }
}
