import SwiftUI
import Charts

// Задача: дашборд — динамика цены за галлон и траты по месяцам
struct FuelDashboardView: View {
    let entries: [FuelEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            priceChart
            spendingChart
        }
        .padding(.vertical, 8)
    }

    // Задача: график цены за галлон по датам (линия)
    private var priceChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price per gallon")
                .font(.headline)
            Chart(entries.sorted { $0.date < $1.date }) { entry in
                LineMark(x: .value("Date", entry.date, unit: .day),
                         y: .value("Price", entry.pricePerGallon))
                PointMark(x: .value("Date", entry.date, unit: .day),
                          y: .value("Price", entry.pricePerGallon))
            }
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
            .frame(height: 150)
        }
    }

    // Задача: траты по месяцам (столбики)
    private var spendingChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spending by month")
                .font(.headline)
            Chart(monthlyTotals, id: \.month) { item in
                BarMark(x: .value("Month", item.month, unit: .month),
                        y: .value("Total", item.total))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
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
            .frame(height: 150)
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
