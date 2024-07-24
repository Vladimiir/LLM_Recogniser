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
        button.setTitle("Camera", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22)
        button.addTarget(self, action: #selector(cameraButtonDidTrigger), for: .touchUpInside)
        return button
    }()

    private var request: VNCoreMLRequest?
    private var captureSession: AVCaptureSession?

    private var boxView: BoxView?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        view.addSubview(cameraButton)

        NSLayoutConstraint.activate([
            cameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        setupRequest()
        setupCaptureSession()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupBoxesView()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
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

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.frame

        view.layer.addSublayer(preview)

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

    private func visionRequestDidComplete(request: VNRequest,
                                          error: Error?) {
        if let prediction = (request.results as? [VNRecognizedObjectObservation])?.first {
            DispatchQueue.main.async {
                self.boxView?.drawBox(with: [prediction])
            }
        }
    }

    private func setupBoxesView() {
        let boxView = BoxView()
        boxView.frame = view.frame

        view.addSubview(boxView)
        self.boxView = boxView
    }

    @objc func cameraButtonDidTrigger() {
        let cameraVc = UIImagePickerController()
        cameraVc.sourceType = .camera
        present(cameraVc, animated: true, completion: nil)
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
