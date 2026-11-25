import SwiftUI

// Задача: экран справочника проверок — разделы по поводу заезда, в них группы по узлам.
// Пункт в две колонки: слева название по-английски и под ним по-русски, справа пояснение.
// Открывается в альбомной ориентации, при выходе — снова портретная
struct MaintenanceChecksView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(MaintenanceChecks.sections) { section in
                    CheckSectionView(section: section)
                }
                ResultsView()
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(MaintenanceChecks.notes, id: \.self) { note in
                        Text("• \(note)")
                    }
                }
                .font(.subheadline)
                Text(MaintenanceChecks.source)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Maintenance Checks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .landscapeOnly()
    }
}

// Задача: раздел — заголовок на двух языках, строка «когда и где», группы проверок
private struct CheckSectionView: View {
    let section: MaintenanceCheckSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(section.english)
                    .font(.title3.weight(.semibold))
                Text(section.russian)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(section.intro)
                .font(.subheadline)
            ForEach(section.groups) { group in
                CheckGroupView(group: group)
            }
        }
    }
}

// Задача: группа одного узла — серый подзаголовок, проверки через разделитель, сноска под ними
private struct CheckGroupView: View {
    let group: MaintenanceCheckGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = group.title {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            ForEach(group.checks) { check in
                Divider()
                CheckRow(check: check)
            }
            Divider()
            if let footnote = group.footnote {
                Text(footnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Задача: строка проверки — слева английское название жирным и русское под ним, справа пояснение
private struct CheckRow: View {
    let check: MaintenanceCheck

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text(check.english)
                    .fontWeight(.semibold)
                Text(check.russian)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .frame(width: 320, alignment: .leading)
            Text(check.note ?? "")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// Задача: как сервисы пишут итог проверки — та же строка, что у проверки
private struct ResultsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Results")
                    .font(.title3.weight(.semibold))
                Text("Результаты проверок — так сервисы пишут итог в документе")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(MaintenanceChecks.results) { result in
                Divider()
                HStack(alignment: .top, spacing: 20) {
                    Text(result.english)
                        .fontWeight(.semibold)
                        .frame(width: 320, alignment: .leading)
                    Text(result.russian)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.subheadline)
            }
            Divider()
        }
    }
}
