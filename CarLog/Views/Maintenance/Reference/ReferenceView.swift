import SwiftUI
import SwiftData

// Задача: экран Maintenance Reference — все справочники по обслуживанию в одном месте:
// план работ на сезон, работы, группы работ, дилерская таблица Acura, проверки при обслуживании и переводы названий;
// внизу — заметки к визиту в сервис
struct ReferenceView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [CarProfile]
    @FocusState private var isEditingNotes: Bool

    var body: some View {
        List {
            referenceLinks
            notesSection
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            // Пока правятся заметки — Done в навигации: он закрывает клавиатуру
            if isEditingNotes {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isEditingNotes = false }
                }
            }
        }
        .onAppear(perform: createProfileIfNeeded)
    }

    // Задача: строки справочников — тап открывает справочник
    @ViewBuilder
    private var referenceLinks: some View {
        NavigationLink {
            ServicePlanView()
        } label: {
            ReferenceRow(title: "Maintenance plan", subtitle: ServicePlan.title)
        }
        NavigationLink {
            ServicesView()
        } label: {
            ReferenceRow(title: "Services", subtitle: "Services with intervals and notes")
        }
        NavigationLink {
            ServiceGroupsView()
        } label: {
            ReferenceRow(title: "Service groups", subtitle: "What is done together")
        }
        NavigationLink {
            MaintenanceGuideView()
        } label: {
            ReferenceRow(title: "Maintenance guide", subtitle: MaintenanceGuide.title)
        }
        NavigationLink {
            MaintenanceChecksView()
        } label: {
            ReferenceRow(title: "Maintenance checks", subtitle: "What to check and when")
        }
        NavigationLink {
            ServiceNamesView()
        } label: {
            ReferenceRow(title: "Service names", subtitle: "English and Russian")
        }
    }

    // Задача: заметки к визиту — пометки перед поездкой в центр и готовые сообщения для мастера.
    // Правятся прямо здесь, поле растёт по тексту; крестик очищает всё после визита
    @ViewBuilder
    private var notesSection: some View {
        if let car = profiles.first {
            Section("Notes") {
                TextField("Notes for the next service visit", text: notesText(car), axis: .vertical)
                    .focused($isEditingNotes)
                    .clearButton(text: notesText(car))
            }
        }
    }

    private func notesText(_ car: CarProfile) -> Binding<String> {
        Binding(get: { car.serviceNotes }, set: { car.serviceNotes = $0 })
    }

    // Задача: заметки хранятся у машины, а запись о машине создаётся при первом открытии Info —
    // если Info ещё не открывали, создать её здесь
    private func createProfileIfNeeded() {
        if profiles.isEmpty { context.insert(CarProfile()) }
    }
}

// Задача: строка справочника — название, ниже серым что внутри
private struct ReferenceRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
