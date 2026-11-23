import SwiftUI

// Задача: вкладка Documents — два списка под переключателем: оплаты страховки и продления регистрации.
// Внутри каждого — стандартная пара «список → карточка», в карточке поля, документы и примечание
struct DocumentsView: View {
    @State private var section: DocumentsSection = .insurance

    var body: some View {
        NavigationStack {
            Group {
                switch section {
                case .insurance: InsuranceListView()
                case .registration: RegistrationListView()
                }
            }
            .safeAreaInset(edge: .top) {
                Picker("Section", selection: $section) {
                    ForEach(DocumentsSection.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Задача: разделы вкладки — подпись в переключателе
enum DocumentsSection: String, CaseIterable, Identifiable {
    case insurance, registration

    var id: String { rawValue }

    var label: String {
        switch self {
        case .insurance: "Insurance"
        case .registration: "Registration"
        }
    }
}
