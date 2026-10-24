import SwiftUI
import Charts

// Задача: виды графиков для вкладки Stats — какие графики есть и как они называются
enum FuelChartKind: String, CaseIterable, Identifiable, Hashable {
    case price
    case spending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .price: "Price per gallon"
        case .spending: "Spending by month"
        }
    }
}

// Задача: показать нужный график по его виду
struct FuelChart: View {
    let kind: FuelChartKind
    let entries: [FuelEntry]

    var body: some View {
        switch kind {
        case .price: PriceChart(entries: entries)
        case .spending: SpendingChart(entries: entries)
        }
    }
}

// Задача: график цены за галлон по датам (линия)
struct PriceChart: View {
    let entries: [FuelEntry]

    var body: some View {
        Chart(entries.sorted { $0.date < $1.date }) { entry in
            LineMark(x: .value("Date", entry.date, unit: .day),
                     y: .value("Price", entry.pricePerGallon))
            PointMark(x: .value("Date", entry.date, unit: .day),
                      y: .value("Price", entry.pricePerGallon))
        }
        .foregroundStyle(Color.accentColor)
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text(price.asMoney)
                    }
                }
            }
        }
    }
}

// Задача: траты по месяцам (столбики)
struct SpendingChart: View {
    let entries: [FuelEntry]

    var body: some View {
        Chart(monthlyTotals, id: \.month) { item in
            BarMark(x: .value("Month", item.month, unit: .month),
                    y: .value("Total", item.total),
                    width: .ratio(0.5))
        }
        .foregroundStyle(Color.accentColor)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let total = value.as(Double.self) {
                        Text(total.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    }
                }
            }
        }
    }

    // Задача: сложить стоимость заправок внутри каждого месяца
    private var monthlyTotals: [(month: Date, total: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) {
            calendar.dateInterval(of: .month, for: $0.date)?.start ?? $0.date
        }
        return grouped
            .map { (month: $0.key, total: $0.value.reduce(0) { $0 + $1.total }) }
            .sorted { $0.month < $1.month }
    }
}
