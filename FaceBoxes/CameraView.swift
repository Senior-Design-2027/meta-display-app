import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    // Creates the UIKit controller that owns the camera session and overlay.
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController()
    }

    // The controller updates itself as camera frames arrive.
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
