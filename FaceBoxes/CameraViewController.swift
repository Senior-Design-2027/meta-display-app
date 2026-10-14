import AVFoundation
import UIKit
import Vision

final class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()

    // Camera setup and frame processing use separate queues to keep the interface responsive.
    private let sessionQueue = DispatchQueue(label: "com.example.FaceBoxes.session")
    private let videoQueue = DispatchQueue(label: "com.example.FaceBoxes.video")

    // A single shape layer draws every face box over the camera preview.
    private let faceBoxesLayer = CAShapeLayer()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    private var isCaptureSessionConfigured = false

    // Builds the full-screen preview and asks for camera access when needed.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        faceBoxesLayer.fillColor = UIColor.clear.cgColor
        faceBoxesLayer.strokeColor = UIColor.systemYellow.cgColor
        faceBoxesLayer.lineWidth = 3
        view.layer.addSublayer(faceBoxesLayer)

        requestCameraAccess()
    }

    // Restarts an already configured camera session when the view returns.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [weak self] in
            guard let self, self.isCaptureSessionConfigured, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }

    // Keeps the preview and its overlay fitted to the screen after rotation or resizing.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        faceBoxesLayer.frame = view.bounds
    }

    // Stops camera work when the view is no longer visible.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    // Requests permission once, then configures the camera off the main thread.
    private func requestCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            sessionQueue.async { [weak self] in self?.configureCaptureSession() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                self?.sessionQueue.async { [weak self] in self?.configureCaptureSession() }
            }
        default:
            break
        }
    }

    // Connects the front camera to the preview and a Vision-ready frame output.
    private func configureCaptureSession() {
        guard !isCaptureSessionConfigured else { return }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(input)
        else {
            captureSession.commitConfiguration()
            return
        }

        captureSession.addInput(input)

        let output = AVCaptureVideoDataOutput()

        // Dropping late frames prevents detection work from falling behind the live camera.
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: videoQueue)

        guard captureSession.canAddOutput(output) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(output)

        if let connection = output.connection(with: .video) {
            // Portrait rotation and mirroring make analyzed pixels match the selfie preview.
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        captureSession.commitConfiguration()
        isCaptureSessionConfigured = true

        DispatchQueue.main.async { [weak self] in
            guard let connection = self?.previewLayer.connection else { return }
            connection.automaticallyAdjustsVideoMirroring = false
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        captureSession.startRunning()
    }

    // Runs Apple's built-in Vision face detector on each camera frame.
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest { [weak self] request, _ in
            let boxes = (request.results as? [VNFaceObservation])?.map(\.boundingBox) ?? []

            // Core Animation layers must be updated on the main thread.
            DispatchQueue.main.async { self?.drawFaceBoxes(boxes) }
        }

        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up).perform([request])
    }

    // Converts Vision coordinates into preview coordinates and draws one path for all faces.
    private func drawFaceBoxes(_ boxes: [CGRect]) {
        let path = UIBezierPath()

        for box in boxes {
            // Vision uses a lower-left origin, while preview metadata uses an upper-left origin.
            let metadataBox = CGRect(
                x: box.minX,
                y: 1 - box.maxY,
                width: box.width,
                height: box.height
            )
            path.append(UIBezierPath(rect: previewLayer.layerRectConverted(fromMetadataOutputRect: metadataBox)))
        }

        faceBoxesLayer.path = path.cgPath
    }
}
