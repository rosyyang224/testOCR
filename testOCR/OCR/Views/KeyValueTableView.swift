import SwiftUI

struct KeyValueTableView: View {
    @Binding var keyValuePairs: [RecognizedKeyValue]
    var onValueChanged: ((Int, String) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(keyValuePairs.indices, id: \.self) { index in
                rowView(for: index)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding()
    }

    @ViewBuilder
    private func rowView(for index: Int) -> some View {
        let bindingValue = Binding<String>(
            get: { keyValuePairs[index].value ?? "" },
            set: { newValue in
                keyValuePairs[index].value = newValue
                onValueChanged?(index, newValue)
            }
        )

        KeyValueTableRowView(
            key: keyValuePairs[index].key,
            value: bindingValue
        )
        .background(index % 2 == 0 ? Color.secondary.opacity(0.05) : .clear)
    }
}

struct KeyValueTableRowView: View {
    let key: String
    @Binding var value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(key)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)

            TextField("Enter value", text: $value)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var pairs: [RecognizedKeyValue] = [
            RecognizedKeyValue(key: "Name", value: "Alice"),
            RecognizedKeyValue(key: "Passport", value: "X1234567"),
        ]

        var body: some View {
            KeyValueTableView(keyValuePairs: $pairs)
        }
    }

    return PreviewWrapper()
}
