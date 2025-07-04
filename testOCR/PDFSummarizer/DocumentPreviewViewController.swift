import SwiftUI

struct DocumentPreviewView: View {
    let image: CGImage

    var body: some View {
        GeometryReader { geometry in
            Image(decorative: image, scale: 1.0)
                .resizable()
                .scaledToFit()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black.opacity(0.05))
        }
        .ignoresSafeArea()
    }
}
