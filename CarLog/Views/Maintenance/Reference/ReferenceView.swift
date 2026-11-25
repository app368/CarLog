import SwiftUI

// Задача: экран Maintenance Reference — все справочники по обслуживанию в одном месте:
// план работ на сезон, работы, группы работ, дилерская таблица Acura, проверки при обслуживании и переводы названий
struct ReferenceView: View {
    var body: some View {
        List {
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
