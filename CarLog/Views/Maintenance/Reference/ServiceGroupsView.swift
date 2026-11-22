import SwiftUI

// Задача: справочник групп работ — название группы, ниже входящие в неё работы.
// Внизу — работы, которые делаются отдельно
struct ServiceGroupsView: View {
    var body: some View {
        List {
            Section {
                ForEach(ServiceGroups.all) { group in
                    NavigationLink {
                        ServiceGroupDetailView(group: group)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.name)
                            Text(group.services.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Done separately") {
                ForEach(ServiceGroups.separate, id: \.self) { name in
                    Text(name)
                }
            }
        }
        .navigationTitle("Service Groups")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Задача: карточка группы — обязательно вместе, обычно вместе, регламент Acura, практика сервисных центров
struct ServiceGroupDetailView: View {
    let group: ServiceGroup

    var body: some View {
        List {
            if !group.required.isEmpty {
                Section {
                    ForEach(group.required, id: \.self) { Text($0) }
                } header: {
                    Text("Required together")
                } footer: {
                    Text("Always done in one visit.")
                }
            }
            if !group.usual.isEmpty {
                Section {
                    ForEach(group.usual, id: \.self) { Text($0) }
                } header: {
                    Text("Usually together")
                } footer: {
                    Text("Often done in the same visit, but can be done separately.")
                }
            }
            Section("Acura") {
                Text(group.acura)
            }
            if !group.centers.isEmpty {
                Section("Service centers") {
                    ForEach(group.centers, id: \.self) { Text($0) }
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
