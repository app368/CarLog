import SwiftUI

// Задача: крестик справа в поле примечания — очистить текст одним тапом.
// Виден, только когда в поле есть текст; перед очисткой спрашивает подтверждение,
// потому что примечания бывают длинные, а промахнуться легко. Общий для всех полей Notes
struct ClearButton: ViewModifier {
    @Binding var text: String
    @State private var isConfirming = false

    func body(content: Content) -> some View {
        HStack(alignment: .top, spacing: 8) {
            content
            if !text.isEmpty {
                Button {
                    isConfirming = true
                } label: {
                    // Серый, как крестик в поле поиска: .tertiary внутри кнопки окрасился бы в цвет акцента
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
                // Без borderless тап по крестику срабатывает на всю строку списка
                .buttonStyle(.borderless)
                .accessibilityLabel("Clear notes")
            }
        }
        .confirmationDialog("Clear notes?", isPresented: $isConfirming, titleVisibility: .visible) {
            Button("Clear Notes", role: .destructive) { text = "" }
        }
    }
}

extension View {
    // Задача: поле примечания с крестиком очистки
    func clearButton(text: Binding<String>) -> some View {
        modifier(ClearButton(text: text))
    }
}
