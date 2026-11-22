import SwiftUI
import SwiftData

// Задача: экран Maintenance Visits — визиты в сервис, новые сверху.
// «+» — меню: новый визит или импорт из файла; после сохранения или импорта сразу открывается карточка визита
struct VisitsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Visit.date, order: .reverse) private var visits: [Visit]
    @State private var isAdding = false
    @State private var isPickingFile = false
    @State private var opened: Visit?
    @State private var pendingDelete: Visit?
    @State private var message: String?
    @State private var importNotes: String?
    @State private var imported: Visit?

    var body: some View {
        List {
            ForEach(visits) { visit in
                NavigationLink {
                    VisitDetailView(visit: visit)
                } label: {
                    VisitRow(visit: visit)
                }
            }
            .onDelete { offsets in pendingDelete = offsets.map { visits[$0] }.first }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Visit", systemImage: "plus") { isAdding = true }
                    Button("Import Visit", systemImage: "square.and.arrow.down") { isPickingFile = true }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .navigationDestination(item: $opened) { visit in
            VisitDetailView(visit: visit)
        }
        .sheet(isPresented: $isAdding) {
            VisitFormView(visit: nil) { opened = $0 }
        }
        .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.json]) { result in
            readFile(result)
        }
        .alert("Delete visit?", isPresented: Binding(get: { pendingDelete != nil },
                                                     set: { if !$0 { pendingDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let pendingDelete { context.delete(pendingDelete) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("Its services and document pages will be deleted too.")
        }
        .alert(message ?? "", isPresented: Binding(get: { message != nil },
                                                  set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        }
        .alert("Visit imported", isPresented: Binding(get: { importNotes != nil },
                                                      set: { if !$0 { importNotes = nil } })) {
            Button("OK", role: .cancel) { opened = imported }
        } message: {
            Text(importNotes ?? "")
        }
        .overlay {
            if visits.isEmpty {
                ContentUnavailableView("No visits yet", systemImage: "wrench.and.screwdriver",
                                       description: Text("Tap + to add a visit or import one from a file."))
            }
        }
    }

    // Задача: прочитать файл визита и сразу записать — в визит на эту дату или в новый — и открыть карточку.
    // Если что-то не сошлось, сначала сообщение, карточка — по OK
    private func readFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
            let file = try VisitFile.decode(Data(contentsOf: url))
            let notes = try VisitImporter.problems(for: file, target: nil, in: context)
            let visit = try VisitImporter.apply(file, in: context)
            if notes.isEmpty {
                opened = visit
            } else {
                imported = visit
                importNotes = notes.joined(separator: "\n\n")
            }
        } catch {
            message = "This file can't be imported. \(error.localizedDescription)"
        }
    }
}

// Задача: строка визита — дата и Total, ниже сервисный центр и число строк
struct VisitRow: View {
    let visit: Visit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(visit.date, format: .dateTime.month(.abbreviated).day().year())
                Spacer()
                Text(visit.total.asMoney)
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var subtitle: String {
        let count = visit.lines.count == 1 ? "1 service" : "\(visit.lines.count) services"
        return visit.centerName.isEmpty ? count : "\(visit.centerName) · \(count)"
    }
}
