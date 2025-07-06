import SwiftUI
import PhotosUI
import Vision

struct HomeScreenView: View {
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedCGImage: CGImage? = nil
    @State private var navigateToResult = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    HomeHeaderView()

                    HomeMainCardView {
                        showingImagePicker = true
                    }

                    HomeQuickActionsView {
                        print("View History tapped")
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
            .onChange(of: selectedItem) { oldItem, newItem in
                Task {
                    do {
                        if let data = try await newItem?.loadTransferable(type: Data.self),
                           let ciImage = CIImage(data: data) {
                            let context = CIContext()
                            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                                selectedCGImage = cgImage
                                navigateToResult = true
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
            .navigationDestination(isPresented: $navigateToResult) {
                if let image = selectedCGImage {
                    DocumentResultView(image: image)
                }
            }
        }
    }
}
