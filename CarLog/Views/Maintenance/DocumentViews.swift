import SwiftUI
import UIKit
import VisionKit
import PDFKit

// Задача: снимок страницы для хранения — JPEG, длинная сторона не больше 2400 точек:
// мелкий шрифт счёта читается, а размер файла остаётся разумным
enum PageImage {
    static func jpeg(from image: UIImage) -> Data? {
        let maxSide: CGFloat = 2400
        let longest = max(image.size.width, image.size.height)
        guard longest > maxSide else { return image.jpegData(compressionQuality: 0.7) }
        let scale = maxSide / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.7)
    }
}

// Задача: миниатюра документа в карточке — снимок или первая страница PDF
struct PageThumbnail: View {
    let page: DocumentPage
    @State private var image: UIImage?
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.15)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 72, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
        .contentShape(Rectangle())
        .task(id: page.persistentModelID) {
            // Размер в пикселях экрана — иначе миниатюра выходит мягкой
            let size = CGSize(width: 72 * displayScale, height: 96 * displayScale)
            if page.isPDF {
                image = PDFDocument(data: page.imageData)?.page(at: 0)?.thumbnail(of: size, for: .mediaBox)
            } else {
                image = await UIImage(data: page.imageData)?.byPreparingThumbnail(ofSize: size)
            }
        }
    }
}

// Задача: встроенный сканер документов iPhone — сам находит лист, обрезает и выравнивает.
// По окончании отдаёт снимки страниц; при отмене — пустой список
struct DocumentScanner: UIViewControllerRepresentable {
    static var isSupported: Bool { VNDocumentCameraViewController.isSupported }

    let onFinish: ([UIImage]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onFinish: ([UIImage]) -> Void

        init(onFinish: @escaping ([UIImage]) -> Void) {
            self.onFinish = onFinish
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            onFinish((0..<scan.pageCount).map { scan.imageOfPage(at: $0) })
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onFinish([])
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onFinish([])
        }
    }
}

// Задача: содержимое документа для просмотра — снимок или PDF
enum DocumentContent {
    case image(UIImage)
    case pdf(PDFDocument)

    init?(page: DocumentPage) {
        if page.isPDF {
            guard let document = PDFDocument(data: page.imageData) else { return nil }
            self = .pdf(document)
        } else {
            guard let image = UIImage(data: page.imageData) else { return nil }
            self = .image(image)
        }
    }
}

// Задача: просмотр документов на весь экран — листание, увеличение щипком и двойным тапом,
// перетаскивание; PDF листается своими страницами вниз. Share отдаёт открытый документ файлом
// JPEG или PDF — например, переслать один инвойс. Общий для визита, страховки и регистрации
struct DocumentViewer: View {
    let pages: [DocumentPage]
    let fileStem: String
    @State private var index: Int
    @State private var contents: [DocumentContent] = []
    @State private var files: [URL?] = []
    @Environment(\.dismiss) private var dismiss

    init(pages: [DocumentPage], fileStem: String, start: Int) {
        self.pages = pages
        self.fileStem = fileStem
        _index = State(initialValue: start)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $index) {
                ForEach(contents.indices, id: \.self) { i in
                    Group {
                        switch contents[i] {
                        case .image(let image): ZoomableImage(image: image)
                        case .pdf(let document): PDFDocumentView(document: document)
                        }
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: contents.count > 1 ? .always : .never))
            .background(Color.black)
            .navigationTitle(contents.count > 1 ? "Page \(index + 1) of \(contents.count)" : "Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if let file = currentFile {
                        ShareLink(item: file) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .onAppear(perform: load)
    }

    // Файл открытого сейчас документа — его и отдаёт Share
    private var currentFile: URL? {
        files.indices.contains(index) ? files[index] : nil
    }

    // Задача: подготовить документы для показа и файл каждого для Share —
    // номер в имени тот же, что при отправке всех документов
    private func load() {
        contents = []
        files = []
        for (number, page) in pages.enumerated() {
            guard let content = DocumentContent(page: page) else { continue }
            contents.append(content)
            files.append(DocumentFiles.write(page, number: number + 1, stem: fileStem))
        }
    }
}

// Задача: документы файлами для Share — «Visit 2025-10-30 - 1.jpg», «Insurance 2026-05-01 - 2.pdf»
// во временной папке
enum DocumentFiles {
    static func write(_ pages: [DocumentPage], stem: String) -> [URL] {
        pages.enumerated().compactMap { number, page in write(page, number: number + 1, stem: stem) }
    }

    // Задача: один документ файлом — «Visit 2025-10-30 - 2.jpg»
    static func write(_ page: DocumentPage, number: Int, stem: String) -> URL? {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Share", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("\(stem) - \(number).\(page.isPDF ? "pdf" : "jpg")")
        return (try? page.imageData.write(to: url)) == nil ? nil : url
    }

    // Задача: страницы документа визита — имя файла по дате визита
    static func write(_ visit: Visit) -> [URL] {
        write(visit.sortedPages, stem: visit.fileStem)
    }
}

extension Visit {
    // Задача: начало имени файла документа визита — «Visit 2025-10-30»
    var fileStem: String { "Visit \(date.fileDay)" }
}

// Задача: PDF на весь экран — стандартный PDFView: вписывает страницу в экран,
// увеличение щипком, страницы листаются вниз
struct PDFDocumentView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {}
}

// Задача: картинка с увеличением и перетаскиванием — стандартный UIScrollView
struct ZoomableImage: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> ZoomScrollView {
        ZoomScrollView(image: image)
    }

    func updateUIView(_ view: ZoomScrollView, context: Context) {}
}

// Задача: UIScrollView с картинкой — вписывает её в экран, держит по центру,
// увеличивает до 5 раз; двойной тап — увеличить место тапа или вернуть как было
final class ZoomScrollView: UIScrollView, UIScrollViewDelegate {
    private let imageView = UIImageView()

    init(image: UIImage) {
        super.init(frame: .zero)
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 5
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        if zoomScale == minimumZoomScale {
            let size = fittedSize
            imageView.frame = CGRect(origin: .zero, size: size)
            contentSize = size
        }
        centerImage()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) { centerImage() }

    // Размер картинки, вписанной в экран целиком
    private var fittedSize: CGSize {
        guard let image = imageView.image, image.size.width > 0, image.size.height > 0,
              bounds.width > 0, bounds.height > 0 else { return bounds.size }
        let scale = min(bounds.width / image.size.width, bounds.height / image.size.height)
        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }

    // Пока картинка меньше экрана, она стоит по центру
    private func centerImage() {
        let dx = max(0, (bounds.width - imageView.frame.width) / 2)
        let dy = max(0, (bounds.height - imageView.frame.height) / 2)
        contentInset = UIEdgeInsets(top: dy, left: dx, bottom: dy, right: dx)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if zoomScale > minimumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let size = CGSize(width: bounds.width / 2.5, height: bounds.height / 2.5)
            zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                            width: size.width, height: size.height), animated: true)
        }
    }
}
