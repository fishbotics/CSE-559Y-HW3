//
//  FFTManager.swift
//  Mobile Systems Project 3
//
//  Created by Adam Fishman on 6/1/20.
//  Copyright © 2020 Adam Fishman. All rights reserved.
//

import Foundation
import Accelerate

class FFTManager {
   var bufferLength: vDSP_Length
    var fftSetUp: vDSP.FFT<DSPSplitComplex>
    
    init(bufferLength: UInt) {
        self.bufferLength = vDSP_Length(bufferLength)
        let log2n = vDSP_Length(log2(Float(self.bufferLength)))
        fftSetUp = vDSP.FFT(
            log2n: log2n,
            radix: .radix2,
            ofType: DSPSplitComplex.self
            )!
    }
    
    func fft(buffer: [Float]) -> Int? {
        assert(buffer.count == self.bufferLength)
        // print(self.intensities)
        let halfN = Int(self.bufferLength / 2)
        var forwardInputReal = [Float](repeating: 0, count: halfN)
        var forwardInputImag = [Float](repeating: 0, count: halfN)
        var forwardOutputReal = [Float](repeating: 0, count: halfN)
        var forwardOutputImag = [Float](repeating: 0, count: halfN)
        forwardInputReal.withUnsafeMutableBufferPointer { forwardInputRealPtr in
            forwardInputImag.withUnsafeMutableBufferPointer { forwardInputImagPtr in
                forwardOutputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
                    forwardOutputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
                        
                        // 1: Create a `DSPSplitComplex` to contain the signal.
                        var forwardInput = DSPSplitComplex(realp: forwardInputRealPtr.baseAddress!,
                                                           imagp: forwardInputImagPtr.baseAddress!)
                        
                        // 2: Convert the real values in `self.intensities` to complex numbers.
                        buffer.withUnsafeBytes {
                            vDSP.convert(interleavedComplexVector: [DSPComplex]($0.bindMemory(to: DSPComplex.self)),
                                         toSplitComplexVector: &forwardInput)
                        }
                        
                        // 3: Create a `DSPSplitComplex` to receive the FFT result.
                        var forwardOutput = DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!,
                                                            imagp: forwardOutputImagPtr.baseAddress!)
                        
                        // 4: Perform the forward FFT.
                        fftSetUp.forward(input: forwardInput,
                                         output: &forwardOutput)
                    }
                }
            }
        }
        
        // let componentFrequencies = forwardOutputImag.enumerated().filter {
        //     $0.element < -1
        // }.map {
        //     return $0.offset
        // }
        let componentFrequencies = forwardOutputImag.enumerated().filter {
            $0.element < -1
        }
        if componentFrequencies.count == 0 { return -1 }
        var best_f: Int = 0
        var best_amp: Float = 0
        for (f, a) in componentFrequencies {
            if a < best_amp {
                best_f = f
                best_amp = a
            }
        }
        return best_f
    }
}
