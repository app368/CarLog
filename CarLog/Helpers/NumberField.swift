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
