//
//  ViewController.swift
//  LLM_Recognizer
//
//  Created by Vladimir Stasenko on 24.07.2024.
//

import UIKit

class ViewController: UIViewController {

    lazy var cameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Camera", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22)
        button.addTarget(self, action: #selector(cameraButtonDidTrigger), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        view.addSubview(cameraButton)

        NSLayoutConstraint.activate([
            cameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc func cameraButtonDidTrigger() {
        let cameraVc = UIImagePickerController()
        cameraVc.sourceType = .camera
        present(cameraVc, animated: true, completion: nil)
    }
}

