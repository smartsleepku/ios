//
//  File.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import UIKit
import AVFoundation

class AudioService {
    
    private let queue = DispatchQueue(label: "dk.ku.sund.SmartSleep.audio")
    private var session: AVCaptureSession?
    private(set) lazy var delegate: SampleBufferDelegate = {
        let delegate = SampleBufferDelegate()
        delegate.sampleBufferCallbackQueue = self.queue
        return delegate
    }()
    let observer = AudioObserver()
    
    var recording: Bool {
        get {
            return session?.isRunning ?? false
        }
    }
    
    func startRecording() {
        let output = AVCaptureAudioDataOutput()
        output.setSampleBufferDelegate(delegate, queue: queue)
        let session = AVCaptureSession()
        queue.async {
            do {
                guard let device = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified) else { return }
                session.beginConfiguration()
                let input = try AVCaptureDeviceInput(device: device)
                session.addInput(input)
                session.addOutput(output)
                output.connection(with: .audio)?.isEnabled = true
                session.commitConfiguration()
                session.startRunning()
            } catch let error {
                print(error)
            }
        }
        self.session = session
    }
    
    func stopRecording() {
        session?.stopRunning()
        session = nil
    }
    
    func verifyAuthorization(controller: UIViewController) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            guard granted == false else { return }
            DispatchQueue.main.async {
                let alert = UIAlertController(title: NSLocalizedString("Title",
                                                                       tableName: "AudioService",
                                                                       bundle: .main,
                                                                       value: "Mikrofon",
                                                                       comment: ""),
                                              message: NSLocalizedString("Body",
                                                                         tableName: "AudioService",
                                                                         bundle: .main,
                                                                         value: "Støjmåleren er nødvendig for at kunne måle søvnrytmer. " +
                                                                                "Giv tilladelse til at bruge mikrofonen i Indstillinger.",
                                                                         comment: ""),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                                              style: .default,
                                              handler: { action in
                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                          options: [:],
                                                                          completionHandler: nil)
                }))
                controller.present(alert, animated: true, completion: nil)
            }
        }
    }
}
