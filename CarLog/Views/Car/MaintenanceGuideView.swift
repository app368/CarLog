import SwiftUI
import SwiftData

// Задача: экран регламента — полная таблица: интервалы в приложении рядом с дилерскими интервалами Acura.
// Открывается в альбомной ориентации, чтобы все колонки уместились по ширине
struct MaintenanceGuideView: View {
    @Query private var schedule: [MaintenanceItem]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow {
                        Text("Code")
                        Text("Work")
                        Text("In app")
                        Text("Acura")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    Divider()
                    ForEach(MaintenanceGuide.rows) { row in
                        GridRow {
                            Text(row.code)
                                .gridColumnAlignment(.center)
                            Text(row.work)
                            Text(appInterval(for: row))
                                .foregroundStyle(Color.accentColor)
                            Text(row.acura)
                        }
                        .font(.subheadline)
                        Divider()
                    }
                }
                Text(MaintenanceGuide.source)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Maintenance · \(MaintenanceGuide.title)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .landscapeOnly()
    }

    // Задача: текущий интервал из нормативов приложения — меняется вместе с правками на вкладке Service
    private func appInterval(for row: MaintenanceGuideRow) -> String {
        guard let name = row.appItem, let item = schedule.first(where: { $0.name == name }) else { return "—" }
        return item.intervalShort
    }
}
