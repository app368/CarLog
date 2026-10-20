import SwiftUI

// Задача: у цифровой клавиатуры нет кнопки закрытия — добавляем Done над клавиатурой
// и закрытие клавиатуры прокруткой формы
struct KeyboardDoneButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
    }
}

extension View {
    func keyboardDoneButton() -> some View {
        modifier(KeyboardDoneButton())
    }
}
