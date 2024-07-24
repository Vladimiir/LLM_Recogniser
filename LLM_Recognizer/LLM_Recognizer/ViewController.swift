//
//  ViewController.swift
//  LLM_Recognizer
//
//  Created by Vladimir Stasenko on 24.07.2024.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {

    lazy var cameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 22)
        button.addTarget(self, action: #selector(cameraButtonDidTrigger), for: .touchUpInside)
        return button
    }()

    lazy var previewView: PreviewView = {
        let view = PreviewView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // TODO: calculate the previewLayer frame
        view.backgroundColor = .lightGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 20
        return view
    }()

    lazy var boxView: BoxView = {
        let view = BoxView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .green.withAlphaComponent(0.1)
        return view
    }()

    private var request: VNCoreMLRequest?
    private var captureSession: AVCaptureSession?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupRequest()
        setupCaptureSession()
    }

    private func setupUI() {
        updateCameraButtonTitle()

        view.backgroundColor = .white

        view.addSubview(cameraButton)
        view.addSubview(previewView)
        view.addSubview(boxView)

        NSLayoutConstraint.activate([
            cameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                constant: -20),

            previewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                 constant: 20),
            previewView.bottomAnchor.constraint(equalTo: cameraButton.topAnchor,
                                                constant: -20),
            previewView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                  constant: -20),

            boxView.centerXAnchor.constraint(equalTo: previewView.centerXAnchor),
            boxView.centerYAnchor.constraint(equalTo: previewView.centerYAnchor),
            boxView.widthAnchor.constraint(equalTo: previewView.widthAnchor),
            boxView.heightAnchor.constraint(equalTo: previewView.heightAnchor)
        ])
    }

    private func setupRequest() {
        let configuration = MLModelConfiguration()

        guard let model = try? CarBrandIconDetector_1(configuration: configuration).model,
              let visionModel = try? VNCoreMLModel(for: model)
        else {
            return
        }

        request = VNCoreMLRequest(model: visionModel,
                                  completionHandler: visionRequestDidComplete)
        request?.imageCropAndScaleOption = .centerCrop
    }

    private func setupCaptureSession() {
        let session = AVCaptureSession()

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            print("Couldn't create video input")
            return
        }

        session.addInput(input)

        previewView.previewLayer = AVCaptureVideoPreviewLayer(session: session)

        let queue = DispatchQueue(label: "videoQueue", qos: .userInteractive)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)

        if session.canAddOutput(output) {
            session.addOutput(output)

            output.connection(with: .video)?.videoOrientation = .portrait
            session.commitConfiguration()

            captureSession = session
        } else {
            print("Couldn't add video output")
        }
    }

    private func visionRequestDidComplete(request: VNRequest,
                                          error: Error?) {
        if let prediction = (request.results as? [VNRecognizedObjectObservation])?.first {
            DispatchQueue.main.async {
                self.boxView.drawBox(with: [prediction])
            }
        }
    }

    private func startRunning() {
        view.layer.insertSublayer(previewView.previewLayer,
                                  below: boxView.layer)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()

            DispatchQueue.main.async { [weak self] in
                self?.updateCameraButtonTitle()
            }
        }
    }

    private func stopRunning() {
        previewView.previewLayer.removeFromSuperlayer()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()

            DispatchQueue.main.async { [weak self] in
                self?.updateCameraButtonTitle()
            }
        }
    }

    private func updateCameraButtonTitle() {
        let title = captureSession?.isRunning ?? false ? "Stop camera" : "Start camera"
        cameraButton.setTitle(title, for: .normal)
    }

    @objc func cameraButtonDidTrigger() {
        if let captureSession,
           captureSession.isRunning {
            stopRunning()
        } else {
            startRunning()
        }
    }
}

// MARK: - Video Delegate

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let request = request
        else {
            return
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
}
