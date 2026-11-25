import SwiftUI

// Задача: экран плана работ — сверху исходные данные, затем чек-лист «сделать сейчас» в две колонки
// (работа слева, пояснение справа), остальные разделы текстом, внизу открытые вопросы.
// Отметки сохраняются, пока не нажата Start over. Открывается в альбомной ориентации
struct ServicePlanView: View {
    @AppStorage("servicePlanChecked") private var checkedRaw = ""
    @State private var isConfirmingReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(ServicePlan.basis, id: \.self) { line in
                        Text(line)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                checklist
                ForEach(ServicePlan.sections) { section in
                    PlanSectionView(section: section)
                }
                questions
                Text(ServicePlan.source)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Maintenance Plan · \(ServicePlan.title)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Start over") { isConfirmingReset = true }
                    .disabled(checked.isEmpty)
            }
        }
        .confirmationDialog("Clear all checkmarks?", isPresented: $isConfirmingReset, titleVisibility: .visible) {
            Button("Clear Checkmarks", role: .destructive) { checkedRaw = "" }
        }
        .landscapeOnly()
    }

    // Задача: «сделать сейчас» — строки с птичкой: тап ставит или снимает отметку
    private var checklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(english: ServicePlan.now.english, russian: ServicePlan.now.russian)
            ForEach(ServicePlan.now.items) { item in
                Divider()
                Button {
                    toggle(item.id)
                } label: {
                    ChecklistRow(item: item, isChecked: checked.contains(item.id))
                }
                .buttonStyle(.plain)
            }
            Divider()
        }
    }

    // Задача: открытые вопросы — нумерованный список
    private var questions: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(english: "Questions", russian: "Вопросы")
            ForEach(Array(ServicePlan.questions.enumerated()), id: \.offset) { number, question in
                Text("\(number + 1). \(question)")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // Задача: отмеченные пункты — хранятся строкой названий через «|» в настройках приложения
    private var checked: Set<String> {
        Set(checkedRaw.split(separator: "|").map(String.init))
    }

    private func toggle(_ id: String) {
        var set = checked
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        checkedRaw = set.sorted().joined(separator: "|")
    }
}

// Задача: заголовок раздела — по-английски, под ним по-русски
private struct SectionTitle: View {
    let english: String
    let russian: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(english)
                .font(.title3.weight(.semibold))
            Text(russian)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// Задача: строка чек-листа — птичка, слева название по-английски и под ним по-русски, справа пояснение
private struct ChecklistRow: View {
    let item: ServicePlanItem
    let isChecked: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Color.accentColor : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.english)
                        .fontWeight(.semibold)
                    Text(item.russian)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 280, alignment: .leading)
            Text(item.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(Rectangle())
    }
}

// Задача: раздел текстом — заголовок, пояснение, пункты: название по-английски, по-русски, ниже текст
private struct PlanSectionView: View {
    let section: ServicePlanSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(english: section.english, russian: section.russian)
            if let intro = section.intro {
                Text(intro)
                    .font(.subheadline)
            }
            ForEach(section.items) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Text(item.english).fontWeight(.semibold)) — \(item.russian)")
                    Text(item.text)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
