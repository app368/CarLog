import SwiftUI

// Задача: вкладка Maintenance — три экрана под переключателем: график, визиты и справочники
struct MaintenanceView: View {
    @State private var section: MaintenanceSection = .schedule

    var body: some View {
        NavigationStack {
            Group {
                switch section {
                case .schedule: ScheduleView()
                case .visits: VisitsView()
                case .reference: ReferenceView()
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
    case schedule, visits, reference

    var id: String { rawValue }

    var label: String {
        switch self {
        case .schedule: "Schedule"
        case .visits: "Visits"
        case .reference: "Reference"
        }
    }

    var title: String { "Maintenance \(label)" }
}
