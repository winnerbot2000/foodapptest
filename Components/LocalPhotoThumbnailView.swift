import SwiftUI
import UIKit

struct LocalPhotoThumbnailView: View {
    @EnvironmentObject private var appState: AppState

    let reference: PhotoReference
    var size: CGFloat = 60
    var cornerRadius: CGFloat = 14

    @State private var image: UIImage?
    @State private var didAttemptLoad = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.secondarySystemBackground))

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if didAttemptLoad {
                Image(systemName: "photo")
                    .foregroundColor(AppColors.secondary)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: reference.relativePath) {
            didAttemptLoad = false
            if let imageData = await appState.loadPhotoData(reference) {
                image = UIImage(data: imageData)
            } else {
                image = nil
            }
            didAttemptLoad = true
        }
    }
}
