//
//  CameraManager.swift
//  Mobile Systems Project 3
//
//  Created by Adam Fishman on 6/1/20.
//  Copyright © 2020 Adam Fishman. All rights reserved.
//

import Foundation
import UIKit
import Accelerate

class CameraManager: ObservableObject, FrameExtractorDelegate {
    var frameExtractor: FrameExtractor!
    var fftManager: FFTManager
    var intensityBuffer: [Float] = []
    var calibrated = false
    let bufferLength: UInt = 24
    let useFFT = true
    let onePattern: [Int]  = [[Int]](repeating: [0, 1], count: 6).flatMap{$0}
    let zeroPattern: [Int]  = [[Int]](repeating: [0, 0, 1], count: 4).flatMap{$0}
    @Published var capturing = false
    @Published var bitString: String = ""
    
    init() {
        frameExtractor = FrameExtractor()
        fftManager = FFTManager()
        frameExtractor.delegate = self
    }
    
    func captured(intensity: Double) {
        if capturing {
            // print("Intensity: \(intensity)")
            pushToBuffer(intensity: intensity)
            if intensityBuffer.count == bufferLength {
                if useFFT {
                    var best_f = fftManager.fft(buffer: self.intensityBuffer)
                    if best_f == 1 {
                        if !calibrated {
                            calibrated.toggle()
                        }
                        gotOne()
                    }
                    if calibrated {
                        if best_f == 0 {
                        gotZero()
                        }
                        self.intensityBuffer = []
                    }
                } else {
                    checkBufferForPattern()
                }
            }
        }
    }
    
    func checkBufferForPattern() {
        var scoreOne = 0
        var scoreZero = 0
        for i in 0..<bufferLength - 1 {
            let idx = Int(i)
            let value = intensityBuffer[idx + 1] > intensityBuffer[idx] ? 1 : -1
            let oneValue = onePattern[idx + 1] > onePattern[idx] ? 1 : -1
            let zeroValue = zeroPattern[idx + 1] > zeroPattern[idx] ? 1 : -1
            if value != oneValue {
                scoreOne += 1
            }
            if value != zeroValue {
                scoreZero += 1
            }
        }
        print("1: \(scoreOne), 0: \(scoreZero)")
        if scoreOne >= 8 && scoreZero < 8 {
            gotOne()
        } else if scoreOne < 8 && scoreZero >= 8 {
            gotZero()
        }
    }
    
    func gotOne() {
        self.bitString = "\(self.bitString)1"
        self.intensityBuffer = []
    }
    
    func gotZero() {
        self.bitString = "\(self.bitString)0"
        self.intensityBuffer = []
    }
    
    func pushToBuffer(intensity: Double) {
        // Keep the buffer at length 12
        if intensityBuffer.count == bufferLength {
            intensityBuffer.removeFirst()
        }
        // Required float to use the FFT
        intensityBuffer.append(Float(intensity))
        print(intensityBuffer.count)
    }
    
    func toggle_capture() {
        self.capturing.toggle()
    }
    
}
