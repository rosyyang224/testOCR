import SwiftUI
import PhotosUI

struct ImagePickerButton: View {
    var label: String = "Select Image"
    var onImagePicked: (Image) -> Void

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var error: String?

    var body: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo")
                    Text(label)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    do {
                        if let data = try await newItem?.loadTransferable(type: Data.self),
                           let ciImage = CIImage(data: data) {
                            let context = CIContext()
                            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                                let image = Image(decorative: cgImage, scale: 1.0)
                                onImagePicked(image)
                            } else {
                                error = "Failed to convert CIImage to CGImage."
                            }
                        } else {
                            error = "Invalid image data."
                        }
                    } catch {
                        self.error = "Failed to load image: \(error.localizedDescription)"
                    }
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
    ImagePickerButton { image in
        image
            .resizable()
            .scaledToFit()
            .frame(height: 200)
    }
}
