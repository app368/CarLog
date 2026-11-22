import SwiftUI
import SwiftData

// Задача: предпросмотр импорта визита — шапка, строки с ценами и работами, что произойдёт при импорте.
// Работы, которых нет в справочнике, помечены красным: строка импортируется без них
struct VisitImportView: View {
    let file: VisitFile
    var onImport: (Visit) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var visits: [Visit]
    @Query private var centers: [ServiceCenter]
    @Query private var items: [MaintenanceItem]
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Date", value: file.day?.formatted(date: .long, time: .omitted) ?? file.date)
                    LabeledContent("Service center", value: centerName.isEmpty ? "—" : centerName)
                    LabeledContent("Odometer", value: file.odometer?.asMiles ?? "—")
                    LabeledContent("Total") {
                        Text(file.total.asMoney)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                } footer: {
                    Text(summary)
                }
                Section("Services") {
                    ForEach(Array(file.lines.enumerated()), id: \.offset) { _, line in
                        ImportLineRow(line: line, items: items)
                    }
                }
                if let note = file.note, !note.isEmpty {
                    Section("Note") {
                        Text(note)
                    }
                }
            }
            .navigationTitle("Import Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import", action: importVisit)
                }
            }
            .alert(message ?? "", isPresented: Binding(get: { message != nil },
                                                      set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private var existing: Visit? {
        VisitImporter.existingVisit(for: file, in: visits)
    }

    // Задача: центр, который получит визит, — свой у введённого визита, иначе из файла
    private var centerName: String {
        VisitImporter.usesFileCenter(file, existing: existing) ? file.centerName : (existing?.centerName ?? "")
    }

    // Задача: что произойдёт при импорте — новый визит или обновление, новый центр
    private var summary: String {
        var parts: [String] = []
        if existing != nil {
            parts.append("The visit on this date is already here. Its services and odometer will be replaced; "
                + "service center and document pages stay.")
        } else {
            parts.append("A new visit will be created.")
        }
        if VisitImporter.usesFileCenter(file, existing: existing),
           VisitImporter.center(named: file.centerName, in: centers) == nil {
            parts.append("Service center “\(file.centerName)” will be added to the list.")
        }
        return parts.joined(separator: " ")
    }

    // Задача: перенести визит в приложение и открыть его карточку
    private func importVisit() {
        do {
            let visit = try VisitImporter.apply(file, in: context)
            onImport(visit)
            dismiss()
        } catch {
            message = error.localizedDescription
        }
    }
}

// Задача: строка предпросмотра — название и цена, ниже работы; не найденные в справочнике — красным
private struct ImportLineRow: View {
    let line: VisitFile.Line
    let items: [MaintenanceItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(line.name)
                Spacer()
                Text(line.price.asMoney)
            }
            if !found.isEmpty {
                Text(found.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !missing.isEmpty {
                Text("Not found: " + missing.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var found: [String] {
        line.services.compactMap { VisitImporter.service(named: $0, in: items)?.name }
    }

    private var missing: [String] {
        line.services.filter { VisitImporter.service(named: $0, in: items) == nil }
    }
}
