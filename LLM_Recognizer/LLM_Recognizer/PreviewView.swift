//
//  PreviewView.swift
//  LLM_Recognizer
//
//  Created by Vladimir Stasenko on 24.07.2024.
//

import UIKit
import AVFoundation

class PreviewView: UIView {

    var previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        previewLayer.frame = frame
    }
}
