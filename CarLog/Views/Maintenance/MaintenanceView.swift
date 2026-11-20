import SwiftUI

// Задача: вкладка Maintenance — три экрана под переключателем: график, записи и справочник работ
struct MaintenanceView: View {
    @State private var section: MaintenanceSection = .schedule

    var body: some View {
        NavigationStack {
            Group {
                switch section {
                case .schedule: ScheduleView()
                case .records: RecordsView()
                case .services: ServicesView()
                }
            }
            .safeAreaInset(edge: .top) {
                Picker("Section", selection: $section) {
                    ForEach(MaintenanceSection.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle(section.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Задача: разделы вкладки — подпись в переключателе и заголовок экрана
enum MaintenanceSection: String, CaseIterable, Identifiable {
    case schedule, records, services

    var id: String { rawValue }

    var label: String {
        switch self {
        case .schedule: "Schedule"
        case .records: "Records"
        case .services: "Services"
        }
    }

    var title: String { "Maintenance \(label)" }
}
