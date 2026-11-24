import SwiftUI
import SwiftData
import PhotosUI
import PDFKit
import UniformTypeIdentifiers

// Задача: блок Documents в карточке страховки и регистрации — миниатюры документов
// (тап — на весь экран, долгое нажатие — удалить) и Add: сканер, Фото или файл (PDF, JPG, PNG).
// Куда привязать новый документ, говорит карточка через attach
struct AttachedDocumentsSection: View {
    let pages: [DocumentPage]
    let fileStem: String
    let attach: (DocumentPage) -> Void

    @Environment(\.modelContext) private var context
    @State private var isScanning = false
    @State private var isPickingPhotos = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var isPickingFile = false
    @State private var viewerStart: PageIndex?
    @State private var pendingDelete: DocumentPage?
    @State private var message: String?

    var body: some View {
        Section {
            if pages.isEmpty {
                Text("No documents")
                    .foregroundStyle(.secondary)
            } else {
                thumbnails
            }
            addMenu
                .fullScreenCover(isPresented: $isScanning) {
                    DocumentScanner { images in
                        addImages(images)
                        isScanning = false
                    }
                    .ignoresSafeArea()
                }
                .photosPicker(isPresented: $isPickingPhotos, selection: $photoItems, matching: .images)
                .onChange(of: photoItems) {
                    Task { await loadPhotos() }
                }
                .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.pdf, .image],
                              allowsMultipleSelection: true) { result in
                    readFiles(result)
                }
                .fullScreenCover(item: $viewerStart) { start in
                    DocumentViewer(pages: pages, fileStem: fileStem, start: start.index)
                }
                .confirmationDialog("Delete this document?",
                                    isPresented: Binding(get: { pendingDelete != nil },
                                                         set: { if !$0 { pendingDelete = nil } }),
                                    titleVisibility: .visible) {
                    Button("Delete Document", role: .destructive, action: deletePage)
                }
                .alert(message ?? "", isPresented: Binding(get: { message != nil },
                                                          set: { if !$0 { message = nil } })) {
                    Button("OK", role: .cancel) {}
                }
        } header: {
            Text("Documents")
        } footer: {
            if !pages.isEmpty {
                Text("Tap to open. Touch and hold to delete.")
            }
        }
    }

    // Задача: миниатюры в ряд, с прокруткой вбок, если их много
    private var thumbnails: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    PageThumbnail(page: page)
                        .onTapGesture { viewerStart = PageIndex(index: index) }
                        .contextMenu {
                            Button("Delete Document", systemImage: "trash", role: .destructive) {
                                pendingDelete = page
                            }
                        }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // Задача: кнопка Add — меню из трёх способов добавить документ
    private var addMenu: some View {
        Menu {
            if DocumentScanner.isSupported {
                Button("Scan Document", systemImage: "doc.viewfinder") { isScanning = true }
            }
            Button("Choose from Photos", systemImage: "photo.on.rectangle") { isPickingPhotos = true }
            Button("Choose File", systemImage: "folder") { isPickingFile = true }
        } label: {
            Label("Add Document", systemImage: "plus")
        }
    }

    // Задача: сохранить снимки документами — по порядку, после уже имеющихся
    private func addImages(_ images: [UIImage]) {
        for image in images {
            if let data = PageImage.jpeg(from: image) { add(data, isPDF: false) }
        }
    }

    // Задача: создать документ и привязать его к карточке
    private func add(_ data: Data, isPDF: Bool) {
        let order = (pages.map(\.order).max() ?? -1) + 1
        let page = DocumentPage(imageData: data, order: order, isPDF: isPDF)
        context.insert(page)
        attach(page)
    }

    // Задача: загрузить выбранные в Фото снимки
    private func loadPhotos() async {
        guard !photoItems.isEmpty else { return }
        var images: [UIImage] = []
        for item in photoItems {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                images.append(image)
            }
        }
        photoItems = []
        addImages(images)
    }

    // Задача: прочитать выбранные файлы — PDF сохраняется как есть, картинка — как снимок
    private func readFiles(_ result: Result<[URL], Error>) {
        do {
            var failed: [String] = []
            for url in try result.get() {
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                if UTType(filenameExtension: url.pathExtension)?.conforms(to: .pdf) == true,
                   PDFDocument(data: data) != nil {
                    add(data, isPDF: true)
                } else if let image = UIImage(data: data), let jpeg = PageImage.jpeg(from: image) {
                    add(jpeg, isPDF: false)
                } else {
                    failed.append(url.lastPathComponent)
                }
            }
            if !failed.isEmpty {
                message = "This file can't be added: \(failed.joined(separator: ", "))."
            }
        } catch {
            message = "This file can't be added. \(error.localizedDescription)"
        }
    }

    // Задача: удалить документ после подтверждения — сначала отвязать от карточки, чтобы миниатюра ушла сразу
    private func deletePage() {
        guard let page = pendingDelete else { return }
        page.insurance = nil
        page.registration = nil
        page.visit = nil
        context.delete(page)
        pendingDelete = nil
    }
}
