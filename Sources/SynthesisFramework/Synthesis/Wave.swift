//
//  Wave.swift
//  Synthesis
//
//  Created by m4m4 on 09.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
//
 
import Foundation

public typealias WaveForm = Signal

// MARK: Generators

public struct Wave {
    
    func getWave(sampleRate: Int, freq: ParameterType) -> Signal {
            switch Int.random(in: 0...5) {
            case 0,1:
                return whiteNoise()
            case 2:
                return silence()
            case 5:
                return sineWave(sampleRate: sampleRate,
                                frequency: freq)
            default:
                return someWave(sampleRate: sampleRate,
                                frequency: freq)
            }
    }
    
    public static func makeWavesBlocks(sr: Int,
                                       freq: ParameterType,
                                       cc: ParameterType) -> Block {
        let whiteBlock = Block(inputCount: 0,
                               outputCount: 1,
                               process: { _ in
                                [ Wave().getWave(sampleRate: sr, freq: freq)]
        })
        let adsr = Block(inputCount: 1, outputCount: 1, process: { inputs in inputs.map { pinkFilter(x: $0) } } )
        let pinkNoise = whiteBlock >- adsr -< identity(inputs: Int(cc))
        return pinkNoise
    }
   
    public static func makeWavesBlocks(sr: Int,
                                cc: ParameterType,
                                length: Int,
                                time: Int) -> Block {
        let whiteBlock = Block(inputCount: 0,
                               outputCount: 1,
                               process: { _ in
                                [ Wave.makeWaves(sr: sr, length: length, time: time)]
        })
        let adsr = Block(inputCount: 1, outputCount: 1, process: { inputs in inputs.map { pinkFilter(x: $0) } } )
        let pinkNoise = whiteBlock >- adsr -< identity(inputs: Int(cc))
        return pinkNoise
    }
    
    static func makePhi(sr: Int, fr:ParameterType) -> ParameterType {
        fr / ParameterType(sr)
    }
    
    static func makeWaves(sr: Int,
                           length: Int,
                           time: Int) -> WaveForm {
        
        let ø = (0..<time).map{ _ in Int.random(in: 1...time) - 1}
        let øø = (0..<time).map{ _ in ParameterType.random(in: 16...432)}
        let ƒ = (length  * time)
        
        return { i in
            let øøø = ø[  ( (i % ƒ) /  length ) ] //swample index
            switch øøø {
            case 0: //wn
                return SampleType(-1.0 + 2.0 * (SampleType(arc4random_uniform(UInt32(Int16.max))) / SampleType(Int16.max)))
            case 1: //sine
                 return SampleType(sin(2.0 * ParameterType(i) * makePhi(sr: sr, fr: øø[øøø]) * ParameterType(Double.pi)))
            case 2: //somewave
                let amp = SampleType(cos(0.007 * makePhi(sr: sr, fr: øø[øøø]) * ParameterType(i - 1)))
                return SampleType(sin(2.0 * ParameterType(i - 1) * makePhi(sr: sr, fr: øø[øøø]) * ParameterType(Double.pi))) * amp
            default: //silence
                return SampleType(0)
            }
        }
    }

}

///// Generate a sine wave
public func sineWave(sampleRate: Int, frequency: ParameterType) -> WaveForm {
    let phi = frequency / ParameterType(sampleRate)
    return { i in
        return SampleType(sin(2.0 * ParameterType(i) * phi * ParameterType(Double.pi)))
    }
}

// MARK: Generators

/// Generate a some wave
public func someWave(sampleRate: Int, frequency: ParameterType) -> WaveForm {
    let phi = frequency / ParameterType(sampleRate)
    return { i in
        let amp = SampleType(cos(0.007 * phi * ParameterType(i - 1)))
        return SampleType(sin(2.0 * ParameterType(i - 1) * phi * ParameterType(Double.pi))) * amp
    }
}

/// Simple white noise generator
public func whiteNoise() -> Signal {
    return { _ in
        return SampleType(-1.0 + 2.0 * (SampleType(arc4random_uniform(UInt32(Int16.max))) / SampleType(Int16.max)))
    }
}

/// Simple white noise generator
public func silence() -> Signal {
    return { _ in
        return SampleType(0)
    }
}
