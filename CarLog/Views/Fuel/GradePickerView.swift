import SwiftUI
import SwiftData

// Задача: список марок бензина — выбор тапом, добавление «+», правка и удаление свайпом
struct GradePickerView: View {
    @Binding var selection: FuelGrade?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FuelGrade.name) private var grades: [FuelGrade]
    @State private var isAdding = false
    @State private var editing: FuelGrade?

    var body: some View {
        List {
            ForEach(grades) { grade in
                Button {
                    selection = grade
                    dismiss()
                } label: {
                    HStack {
                        Text(grade.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if grade == selection {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button("Delete", role: .destructive) { delete(grade) }
                    Button("Edit") { editing = grade }
                        .tint(.orange)
                }
            }
        }
        .overlay {
            if grades.isEmpty {
                ContentUnavailableView("No grades", systemImage: "drop",
                                       description: Text("Tap + to add a fuel grade."))
            }
        }
        .navigationTitle("Fuel Grades")
        .toolbar {
            Button("Add", systemImage: "plus") { isAdding = true }
        }
        .sheet(isPresented: $isAdding) {
            GradeFormView(grade: nil) { selection = $0 }
        }
        .sheet(item: $editing) {
            GradeFormView(grade: $0)
        }
    }

    // Задача: удалить марку; если она была выбрана — снять выбор
    private func delete(_ grade: FuelGrade) {
        if grade == selection { selection = nil }
        context.delete(grade)
    }
}

// Задача: форма марки бензина — только название
struct GradeFormView: View {
    let grade: FuelGrade?
    var onCreate: (FuelGrade) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String

    init(grade: FuelGrade?, onCreate: @escaping (FuelGrade) -> Void = { _ in }) {
        self.grade = grade
        self.onCreate = onCreate
        _name = State(initialValue: grade?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
            }
            .navigationTitle(grade == nil ? "New Grade" : "Edit Grade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        if let grade {
            grade.name = cleanName
        } else {
            let new = FuelGrade(name: cleanName)
            context.insert(new)
            onCreate(new)
        }
        dismiss()
    }
}
