import SwiftUI
import SwiftData
import PhotosUI

// Задача: карточка визита — шапка и Total, строки визита (работы с ценами),
// страницы документа из сервиса и примечание внизу. Edit правит шапку;
// строки, страницы и примечание правятся прямо здесь
struct VisitDetailView: View {
    let visit: Visit

    @Environment(\.modelContext) private var context
    @State private var isEditing = false
    @State private var isAddingLine = false
    @State private var editingLine: VisitLine?
    @State private var isScanning = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var viewerStart: PageIndex?
    @State private var pendingPageDelete: DocumentPage?
    @State private var shareFiles: [URL] = []
    @State private var isPickingFile = false
    @State private var message: String?
    @State private var importNotes: String?
    @FocusState private var isEditingNote: Bool

    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: visit.date.formatted(date: .long, time: .omitted))
                LabeledContent("Service center", value: visit.centerName.isEmpty ? "—" : visit.centerName)
                LabeledContent("Odometer", value: visit.odometer?.asMiles ?? "—")
                LabeledContent("Total") {
                    Text(visit.total.asMoney)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }
            linesSection
            documentsSection
            notesSection
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Visit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Пока правится примечание, вместо Edit — Done: он закрывает клавиатуру
            if isEditingNote {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isEditingNote = false }
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { isEditing = true }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            VisitFormView(visit: visit)
        }
        .sheet(isPresented: $isAddingLine) {
            LineFormView(visit: visit, line: nil)
        }
        .sheet(item: $editingLine) { line in
            LineFormView(visit: visit, line: line)
        }
        .fullScreenCover(isPresented: $isScanning) {
            DocumentScanner { images in
                addPages(images)
                isScanning = false
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $viewerStart) { start in
            DocumentViewer(visit: visit, start: start.index)
        }
        .onChange(of: photoItems) {
            Task { await loadPhotos() }
        }
        .confirmationDialog("Delete this page?", isPresented: Binding(get: { pendingPageDelete != nil },
                                                                     set: { if !$0 { pendingPageDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Delete Page", role: .destructive, action: deletePage)
        }
        .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.json]) { result in
            readFile(result)
        }
        .alert(message ?? "", isPresented: Binding(get: { message != nil },
                                                  set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        }
        .alert("Visit imported", isPresented: Binding(get: { importNotes != nil },
                                                      set: { if !$0 { importNotes = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importNotes ?? "")
        }
        .task(id: visit.pages.count) {
            shareFiles = DocumentFiles.write(visit)
        }
    }

    // Задача: прочитать файл визита и сразу записать его в этот визит — строки и пробег заменяются,
    // центр и фото остаются; правки — потом в карточке. Сообщение — только если что-то не сошлось
    private func readFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
            let file = try VisitFile.decode(Data(contentsOf: url))
            let notes = try VisitImporter.problems(for: file, target: visit, in: context)
            _ = try VisitImporter.apply(file, to: visit, in: context)
            if !notes.isEmpty { importNotes = notes.joined(separator: "\n\n") }
        } catch {
            message = "This file can't be imported. \(error.localizedDescription)"
        }
    }

    // Задача: примечание внизу карточки — правится прямо здесь, поле растёт вместе с текстом.
    // Сюда же импорт кладёт ремонт и прочие расходы, не вошедшие в Total
    private var notesSection: some View {
        Section("Notes") {
            TextField("Repairs, extra costs, anything else", text: noteText, axis: .vertical)
                .focused($isEditingNote)
        }
    }

    private var noteText: Binding<String> {
        Binding(get: { visit.note }, set: { visit.note = $0 })
    }

    // Задача: секция строк визита — тап открывает форму строки, свайп удаляет, внизу Add Service
    private var linesSection: some View {
        Section("Services") {
            if visit.lines.isEmpty {
                Text("No services yet")
                    .foregroundStyle(.secondary)
            }
            ForEach(visit.sortedLines) { line in
                Button {
                    editingLine = line
                } label: {
                    VisitLineRow(line: line)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deleteLines)
            Button("Add Service", systemImage: "plus") { isAddingLine = true }
        }
    }

    // Задача: секция документа — сверху съёмка сканером и добавление из Фото,
    // ниже миниатюры страниц (тап — на весь экран, долгое нажатие — удалить),
    // внизу Share (страницы на Mac) и Import (строки из файла визита — в этот визит)
    private var documentsSection: some View {
        Section {
            if DocumentScanner.isSupported {
                Button("Scan Document", systemImage: "doc.viewfinder") { isScanning = true }
            }
            PhotosPicker(selection: $photoItems, matching: .images) {
                Label("Add from Photos", systemImage: "photo.on.rectangle")
            }
            if !visit.pages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(visit.sortedPages.enumerated()), id: \.element.id) { index, page in
                            PageThumbnail(page: page)
                                .onTapGesture { viewerStart = PageIndex(index: index) }
                                .contextMenu {
                                    Button("Delete Page", systemImage: "trash", role: .destructive) {
                                        pendingPageDelete = page
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            if !shareFiles.isEmpty {
                ShareLink(items: shareFiles) {
                    Label("Share Document", systemImage: "square.and.arrow.up")
                }
            }
            Button("Import from File", systemImage: "square.and.arrow.down") { isPickingFile = true }
        } header: {
            Text("Documents")
        } footer: {
            Text("Share sends the pages to your Mac. Import adds the services and prices from the visit file made from them.")
        }
    }

    // Задача: удалить строки свайпом
    private func deleteLines(at offsets: IndexSet) {
        let lines = visit.sortedLines
        for line in offsets.map({ lines[$0] }) {
            visit.lines.removeAll { $0 == line }
            context.delete(line)
        }
    }

    // Задача: сохранить снимки страниц в визит — по порядку, после уже имеющихся
    private func addPages(_ images: [UIImage]) {
        var order = (visit.pages.map(\.order).max() ?? -1) + 1
        for image in images {
            guard let data = PageImage.jpeg(from: image) else { continue }
            let page = DocumentPage(imageData: data, order: order)
            context.insert(page)
            page.visit = visit
            order += 1
        }
    }

    // Задача: загрузить выбранные в Фото снимки и добавить их страницами
    private func loadPhotos() async {
        guard !photoItems.isEmpty else { return }
        var images: [UIImage] = []
        for item in photoItems {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                images.append(image)
            }
        }
        photoItems = []
        addPages(images)
    }

    // Задача: удалить страницу после подтверждения
    private func deletePage() {
        guard let page = pendingPageDelete else { return }
        visit.pages.removeAll { $0 == page }
        context.delete(page)
        pendingPageDelete = nil
    }
}

// Задача: номер страницы, с которой открывается просмотр документа
struct PageIndex: Identifiable {
    let index: Int
    var id: Int { index }
}

// Задача: строка визита — название и цена, ниже серым работы из справочника
struct VisitLineRow: View {
    let line: VisitLine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(line.name)
                Spacer()
                Text(line.price.asMoney)
            }
            if !line.services.isEmpty {
                Text(line.servicesText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// Задача: форма строки визита — название, цена и галочки работ из справочника.
// Если название не заполнено, оно собирается из названий отмеченных работ
struct LineFormView: View {
    let visit: Visit
    let line: VisitLine?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MaintenanceItem.name) private var items: [MaintenanceItem]

    @State private var name: String
    @State private var price: String
    @State private var selected: Set<PersistentIdentifier>

    init(visit: Visit, line: VisitLine?) {
        self.visit = visit
        self.line = line
        _name = State(initialValue: line?.name ?? "")
        _price = State(initialValue: line.map { $0.price == 0 ? "" : NumberInput.text($0.price) } ?? "")
        _selected = State(initialValue: Set(line?.services.map(\.persistentModelID) ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name, axis: .vertical)
                    NumberField(title: "Price", text: $price, unit: "USD")
                } footer: {
                    Text("A short name of the line in the service document.")
                }
                Section {
                    ForEach(items) { item in
                        Button {
                            toggle(item)
                        } label: {
                            HStack {
                                Text(item.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected.contains(item.persistentModelID) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Services")
                } footer: {
                    Text("Services done in this line. Last and Next on the schedule are counted from them.")
                }
            }
            .keyboardDoneButton()
            .navigationTitle(line == nil ? "New Service" : "Edit Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedName.isEmpty && selected.isEmpty)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Задача: отметить или снять работу
    private func toggle(_ item: MaintenanceItem) {
        if selected.contains(item.persistentModelID) {
            selected.remove(item.persistentModelID)
        } else {
            selected.insert(item.persistentModelID)
        }
    }

    // Задача: сохранить — обновить строку или добавить новую в конец визита
    private func save() {
        let services = items.filter { selected.contains($0.persistentModelID) }
        let target = line ?? VisitLine(name: "", price: 0, order: (visit.lines.map(\.order).max() ?? -1) + 1)
        if line == nil {
            context.insert(target)
            target.visit = visit
        }
        target.name = trimmedName.isEmpty ? services.map(\.name).joined(separator: ", ") : trimmedName
        target.price = NumberInput.double(price) ?? 0
        target.services = services
        dismiss()
    }
}
