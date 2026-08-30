import AVFoundation
import SwiftUI

/// Thin UIViewRepresentable bridge for AVCaptureVideoPreviewLayer — SwiftUI
/// has no native camera preview view.
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {}
}

final class PreviewContainerView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            if let previewLayer {
                previewLayer.frame = bounds
                layer.addSublayer(previewLayer)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
