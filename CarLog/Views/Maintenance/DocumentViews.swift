import SwiftUI
import UIKit
import VisionKit

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

// Задача: миниатюра страницы документа в карточке визита
struct PageThumbnail: View {
    let page: DocumentPage
    @State private var image: UIImage?

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
            image = await UIImage(data: page.imageData)?.byPreparingThumbnail(ofSize: CGSize(width: 144, height: 192))
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

// Задача: просмотр документа на весь экран — листание страниц, увеличение щипком и двойным тапом,
// перетаскивание; Share отдаёт все страницы файлами JPEG (AirDrop на Mac, Save to Files)
struct DocumentViewer: View {
    let visit: Visit
    @State private var index: Int
    @State private var images: [UIImage] = []
    @State private var files: [URL] = []
    @Environment(\.dismiss) private var dismiss

    init(visit: Visit, start: Int) {
        self.visit = visit
        _index = State(initialValue: start)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $index) {
                ForEach(images.indices, id: \.self) { i in
                    ZoomableImage(image: images[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .always : .never))
            .background(Color.black)
            .navigationTitle(images.count > 1 ? "Page \(index + 1) of \(images.count)" : "Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !files.isEmpty {
                        ShareLink(items: files) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .onAppear(perform: load)
    }

    // Задача: подготовить страницы для показа и файлы для Share — «Visit 2025-10-30 - 1.jpg»
    private func load() {
        let pages = visit.sortedPages
        images = pages.compactMap { UIImage(data: $0.imageData) }
        let day = visit.date.fileDay
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Share", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        files = pages.enumerated().compactMap { number, page in
            let url = folder.appendingPathComponent("Visit \(day) - \(number + 1).jpg")
            return (try? page.imageData.write(to: url)) == nil ? nil : url
        }
    }
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
