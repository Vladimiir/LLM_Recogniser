//
//  BoxView.swift
//  LLM_Recognizer
//
//  Created by Vladimir Stasenko on 24.07.2024.
//

import UIKit
import Vision

final class BoxView: UIView {

    func drawBox(with predictions: [VNRecognizedObjectObservation]) {
        layer.sublayers?.forEach {
            $0.removeFromSuperlayer()
        }

        predictions.forEach {
            drawBox(with: $0)
        }
    }

    private func drawBox(with prediction: VNRecognizedObjectObservation) {
        let scale = CGAffineTransform.identity.scaledBy(x: bounds.width, y: bounds.height)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)

        let rectangle = prediction.boundingBox.applying(transform).applying(scale)

        let newlayer = CALayer()
        newlayer.frame = rectangle

        newlayer.backgroundColor = UIColor.red.withAlphaComponent(0.5).cgColor
        newlayer.cornerRadius = 4

        layer.addSublayer(newlayer)
    }
}
