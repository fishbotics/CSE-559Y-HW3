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
    var fftSetUp:  vDSP_DFT_Setup
    
    init() {
        fftSetUp = vDSP_DFT_zop_CreateSetup(nil, 24, vDSP_DFT_Direction.FORWARD)!
    }
    
    func fft(buffer: [Float]) -> Int? {
        assert(buffer.count == 24)
        var realIn: [Float] = buffer
        var imagIn = [Float](repeating: 0, count: 24)
        var realOut = [Float](repeating: 0, count: 24)
        var imagOut = [Float](repeating: 0, count: 24)
        vDSP_DFT_Execute(fftSetUp, &realIn, &imagIn, &realOut, &imagOut)
        var complex = DSPSplitComplex(realp: &realOut, imagp: &imagOut)
        var magnitudes = [Float](repeating: 0, count: 12)
        vDSP_zvabs(&complex, 1, &magnitudes, 1, 12)
        print(magnitudes)
        let top = magnitudes.enumerated().filter {
            $0.element > 400
        }.sorted {
            $0.element > $1.element
        }.map { return $0.offset }
        if top.count == 1 && top[0] == 0 {
            return 1
        } else if top.count == 2 && top[0] == 0 && top[1] == 6 {
            return 0
        }
        return nil
    }
}
