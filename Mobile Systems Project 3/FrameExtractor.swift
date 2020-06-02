//
//  CameraManager.swift
//  Mobile Systems Project 3
//
//  Created by Adam Fishman on 6/1/20.
//  Copyright © 2020 Adam Fishman. All rights reserved.
//

import Foundation

import UIKit
import AVFoundation

protocol FrameExtractorDelegate: class {
    func captured(intensity: Double)
}

// Inspired by https://medium.com/ios-os-x-development/ios-camera-frames-extraction-d2c0f80ed05a
class FrameExtractor : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var permissionGranted = true
    private let position = AVCaptureDevice.Position.back
    private let quality = AVCaptureSession.Preset.medium
    private let context = CIContext()
    weak var delegate: FrameExtractorDelegate?
    
    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }
    
    // MARK: AVSession configuration
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    private func configureSession() {
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality
        guard let captureDevice = selectCaptureDevice() else { return }
        try! captureDevice.lockForConfiguration();
        captureDevice.exposureMode = AVCaptureDevice.ExposureMode.locked
        captureDevice.whiteBalanceMode = AVCaptureDevice.WhiteBalanceMode.locked
        captureDevice.unlockForConfiguration()
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
    }
        
    private func selectCaptureDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.devices().filter {
            ($0 as AnyObject).hasMediaType(AVMediaType.video) &&
            ($0 as AnyObject).position == position
        }.first as? AVCaptureDevice
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput: CMSampleBuffer, from: AVCaptureConnection) {
        guard let intensity = imageFromSampleBuffer(sampleBuffer: didOutput) else { return }
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.captured(intensity: intensity)
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> Double? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let image = UIImage(cgImage: cgImage)
        guard let value: Double = image.averagePixelIntensity() else { return nil }
        return value
    }
}

extension UIImage {
    func averagePixelIntensity() -> Double? {
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let red = average_n(data: pixelData, start: 0, n: 4)
        let green = average_n(data:pixelData, start: 1, n: 4)
        let blue = average_n(data: pixelData, start: 2, n: 4)
        return (red + green + blue) / 3
        // return pixelData
    }
    
    private func average_n(data: [UInt8], start: size_t, n: size_t) -> Double {
        let indices = Array(stride(from: start, to: data.count, by: n))
        var sum: Double = 0
        for i in indices {
            sum += Double(data[i])
        }
        return sum / Double(indices.count)
        //print(indices)
        //return Double(indices.reduce(0) { $0 + data[$1] }) / Double(indices.count)
        
    }
    
}
