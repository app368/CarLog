import SwiftUI
import SwiftData

// Задача: вкладка Stats — дашборд с карточками графиков; тап открывает график на весь экран
struct StatsView: View {
    @Query(sort: \FuelEntry.date) private var entries: [FuelEntry]

    var body: some View {
        NavigationStack {
            List {
                ForEach(FuelChartKind.allCases) { kind in
                    Section {
                        NavigationLink(value: kind) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(kind.title)
                                    .font(.headline)
                                FuelChart(kind: kind, entries: entries)
                                    .frame(height: 150)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationDestination(for: FuelChartKind.self) { ChartScreen(kind: $0) }
            .overlay {
                // График имеет смысл с двух записей — одна точка линию не рисует
                if entries.count < 2 {
                    ContentUnavailableView("Not enough data", systemImage: "chart.xyaxis.line",
                                           description: Text("Charts appear after two fill-ups."))
                        .background(Color(.systemGroupedBackground))
                }
            }
        }
    }
}

// Задача: один график на весь экран в альбомной ориентации
struct ChartScreen: View {
    let kind: FuelChartKind
    @Query(sort: \FuelEntry.date) private var entries: [FuelEntry]

    var body: some View {
        FuelChart(kind: kind, entries: entries)
            .padding()
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .landscapeOnly()
    }
}
