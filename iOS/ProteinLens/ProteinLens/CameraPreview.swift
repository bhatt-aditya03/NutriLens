// CameraPreview.swift
// ProteinLens — Day 4
// UIViewRepresentable that renders the live AVCaptureSession preview

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

// ── UIView subclass with AVCaptureVideoPreviewLayer ───────────
final class PreviewUIView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    var session: AVCaptureSession? {
        get { previewLayer.session }
        set {
            previewLayer.session     = newValue
            previewLayer.videoGravity = .resizeAspectFill
        }
    }
}
