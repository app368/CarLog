import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// Задача: вкладка Info — данные автомобиля, справочники заправок, сервисных центров и страховых компаний, выгрузка/загрузка
struct InfoView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [CarProfile]

    @State private var exportDocument: BackupDocument?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingImport: Backup?
    @State private var message: String?
    @FocusState private var isEditingCar: Bool

    var body: some View {
        NavigationStack {
            Form {
                if let car = profiles.first {
                    CarProfileSection(car: car, focus: $isEditingCar)
                }
                Section("Lists") {
                    NavigationLink("Gas stations") {
                        GasStationsView()
                    }
                    NavigationLink("Service centers") {
                        ServiceCentersView()
                    }
                    NavigationLink("Insurance companies") {
                        InsuranceCompaniesView()
                    }
                }
                Section {
                    Button("Export Data", systemImage: "square.and.arrow.up", action: exportData)
                    Button("Import Data", systemImage: "square.and.arrow.down") { isImporting = true }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Export saves all records to a file. Import replaces all records on this iPhone with the file's contents.")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                // Задача: кнопка Done над клавиатурой на корневом экране вкладки не появляется —
                // поэтому, пока редактируется поле, Done показывается в навбаре
                if isEditingCar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isEditingCar = false }
                    }
                }
            }
            .navigationTitle("Info")
            .onAppear(perform: createProfileIfNeeded)
            .fileExporter(isPresented: $isExporting, document: exportDocument,
                          contentType: .json, defaultFilename: BackupService.fileName) { result in
                if case .failure(let error) = result { message = error.localizedDescription }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
                readImport(result)
            }
            .alert("Replace all data?", isPresented: Binding(get: { pendingImport != nil },
                                                            set: { if !$0 { pendingImport = nil } })) {
                Button("Replace", role: .destructive, action: applyImport)
                Button("Cancel", role: .cancel) { pendingImport = nil }
            } message: {
                Text("All records on this iPhone will be replaced with \(pendingImport?.recordCount ?? 0) records from the file.")
            }
            .alert(message ?? "", isPresented: Binding(get: { message != nil },
                                                      set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    // Задача: запись о машине одна — создать её при первом открытии вкладки
    private func createProfileIfNeeded() {
        if profiles.isEmpty { context.insert(CarProfile()) }
    }

    // Задача: собрать все записи в файл и предложить сохранить его
    private func exportData() {
        do {
            exportDocument = BackupDocument(data: try BackupService.export(from: context))
            isExporting = true
        } catch {
            message = error.localizedDescription
        }
    }

    // Задача: прочитать выбранный файл и спросить подтверждение перед заменой данных
    private func readImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
            pendingImport = try BackupService.decode(Data(contentsOf: url))
        } catch {
            message = "This file can't be imported. \(error.localizedDescription)"
        }
    }

    // Задача: заменить все записи данными из файла
    private func applyImport() {
        guard let backup = pendingImport else { return }
        pendingImport = nil
        do {
            try BackupService.restore(backup, into: context)
            message = "Imported \(backup.recordCount) records."
        } catch {
            message = error.localizedDescription
        }
    }
}

// Задача: поля данных автомобиля, правки сохраняются сразу
struct CarProfileSection: View {
    @Bindable var car: CarProfile
    var focus: FocusState<Bool>.Binding

    var body: some View {
        Section("Car") {
            LabeledContent("Manufacturer") {
                TextField("Honda", text: $car.manufacturer)
                    .multilineTextAlignment(.trailing)
                    .focused(focus)
            }
            LabeledContent("Make") {
                TextField("Acura", text: $car.make)
                    .multilineTextAlignment(.trailing)
                    .focused(focus)
            }
            LabeledContent("Model") {
                TextField("MDX", text: $car.model)
                    .multilineTextAlignment(.trailing)
                    .focused(focus)
            }
            LabeledContent("Year") {
                TextField("2014", text: yearText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused(focus)
            }
            LabeledContent("VIN") {
                TextField("Optional", text: $car.vin)
                    .textInputAutocapitalization(.characters)
                    .multilineTextAlignment(.trailing)
                    .focused(focus)
            }
            LabeledContent("License plate") {
                TextField("Optional", text: $car.plate)
                    .textInputAutocapitalization(.characters)
                    .multilineTextAlignment(.trailing)
                    .focused(focus)
            }
        }
    }

    // Задача: год хранится числом, а в поле вводится текстом
    private var yearText: Binding<String> {
        Binding(get: { car.year.map(String.init) ?? "" },
                set: { car.year = NumberInput.int($0) })
    }
}
