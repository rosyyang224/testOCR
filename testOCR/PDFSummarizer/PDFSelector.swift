import SwiftUI
import UniformTypeIdentifiers

struct PDFPickerButton: View {
    var label: String = "Select PDF"
    var onPick: (URL?) -> Void

    @State private var showingFileImporter = false
    @State private var error: String?

    var body: some View {
        VStack {
            Button(action: {
                showingFileImporter = true
            }) {
                HStack {
                    Image(systemName: "doc.fill")
                    Text(label)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    onPick(urls.first)
                case .failure:
                    onPick(nil)
                }
            }

            if let error = error {
                Text(error)
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    PDFPickerButton { url in
        print("Picked PDF: \(url?.absoluteString ?? "none")")
    }
}
