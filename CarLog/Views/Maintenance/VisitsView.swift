import SwiftUI
import SwiftData

// Задача: экран Maintenance Visits — визиты в сервис, новые сверху.
// «+» — новый визит или импорт из файла; после сохранения сразу открывается карточка визита
struct VisitsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Visit.date, order: .reverse) private var visits: [Visit]
    @State private var isAdding = false
    @State private var isPickingFile = false
    @State private var importFile: VisitFile?
    @State private var opened: Visit?
    @State private var pendingDelete: Visit?
    @State private var message: String?

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
        .sheet(item: $importFile) { file in
            VisitImportView(file: file) { opened = $0 }
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
        .overlay {
            if visits.isEmpty {
                ContentUnavailableView("No visits yet", systemImage: "wrench.and.screwdriver",
                                       description: Text("Tap + to add a visit or import one from a file."))
            }
        }
    }

    // Задача: прочитать выбранный файл визита и показать предпросмотр
    private func readFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
            importFile = try VisitFile.decode(Data(contentsOf: url))
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
