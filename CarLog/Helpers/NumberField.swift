import SwiftUI

// Задача: строка формы для ввода числа — подпись слева, поле и единица измерения справа
struct NumberField: View {
    let title: String
    @Binding var text: String
    let unit: String
    var keyboard: UIKeyboardType = .decimalPad

    var body: some View {
        HStack {
            Text(title)
            TextField("0", text: $text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}

// Задача: поле телефона форматирует номер по мере ввода и сразу при открытии формы
struct PhoneFormatting: ViewModifier {
    @Binding var text: String
    let isOn: Bool

    func body(content: Content) -> some View {
        content
            .onAppear(perform: reformat)
            .onChange(of: text) { reformat() }
    }

    private func reformat() {
        guard isOn else { return }
        let formatted = PhoneFormat.format(text, typing: true)
        if formatted != text { text = formatted }
    }
}

extension View {
    func phoneFormatting(_ text: Binding<String>, isOn: Bool = true) -> some View {
        modifier(PhoneFormatting(text: text, isOn: isOn))
    }
}
