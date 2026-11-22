import SwiftUI

// Задача: таблица переводов названий работ — английское название, под ним русский перевод
struct ServiceNamesView: View {
    var body: some View {
        List(ServiceNames.rows, id: \.english) { row in
            VStack(alignment: .leading, spacing: 2) {
                Text(row.english)
                Text(row.russian)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Service Names")
        .navigationBarTitleDisplayMode(.inline)
    }
}
