import SwiftUI
import PhotosUI

struct HomeScreenView: View {
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                HomeHeaderView()

                HomeMainCardView {
                    showingImagePicker = true
                }

                HomeQuickActionsView {
                    print("View History tapped")
                    // TODO: Navigate to history screen
                }

                if let image = selectedImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            Task {
                do {
                    if let data = try await newItem?.loadTransferable(type: Data.self),
                       let ciImage = CIImage(data: data) {
                        let context = CIContext()
                        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                            let swiftUIImage = Image(decorative: cgImage, scale: 1.0)
                            selectedImage = swiftUIImage
                            print("Selected Image loaded")
                            // TODO: Navigate to result screen with image
                        } else {
                            errorMessage = "Failed to convert image."
                        }
                    } else {
                        errorMessage = "Invalid image data."
                    }
                } catch {
                    errorMessage = "Image load error: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    HomeScreenView()
}
