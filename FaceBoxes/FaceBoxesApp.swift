import SwiftUI

@main
struct FaceBoxesApp: App {
    var body: some Scene {
        WindowGroup {
            CameraView()
                .ignoresSafeArea()
        }
    }
}
