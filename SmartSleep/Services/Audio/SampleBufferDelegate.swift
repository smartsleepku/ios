//
//  SampleBufferDelegate.swift
//  SmartSleep
//
//  Created by Anders Borch on 25/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import AVFoundation

class SampleBufferDelegate: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    var sampleBufferCallbackQueue: DispatchQueue?
    private(set) var powerLevel: Float = 0.0
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var power: Float = 0.0
        var channels = 0
        connection.audioChannels.forEach { channel in
            power += channel.averagePowerLevel
            channels += 1
        }
        guard channels > 0 else { return }
        powerLevel = power / Float(channels)
    }
}
