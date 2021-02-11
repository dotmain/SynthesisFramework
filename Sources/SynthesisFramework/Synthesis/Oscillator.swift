//
//  Oscillator.swift
//  Synthesis
//
//  Created by m4m4 on 05.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
//
 
import Foundation

public struct Oscillator {
    static var amplitude: Float = 1
    static var frequency: Float = 440
    static let sine = { (time: Float) -> Float in
        return Oscillator.amplitude * sin(Float.pi * Oscillator.frequency * time)
    }
    static let triangle = { (time: Float) -> Float in
        let period = 1.0 / Double(Oscillator.frequency)
        let currentTime = fmod(Double(time), period)
        let value = currentTime / period
        
        
        var result = 0.0
        if value < 0.25 {
            result = value * 4
        } else if value < 0.75 {
            result = 2.0 - (value * 4.0)
        } else {
            result = value * 4 - 4.0
        }
        return Oscillator.amplitude * Float(result)
    }
    static let sawtooth = { (time: Float) -> Float in
        let period = 1.0 / Oscillator.frequency
        let currentTime = fmod(Double(time), Double(period))
        
        return Oscillator.amplitude * ((Float(currentTime) / period) * 2 - 1.0)
    }
    static let square = { (time: Float) -> Float in
        let period = 1.0 / Double(Oscillator.frequency)
        let currentTime = fmod(Double(time), period)
        return ((currentTime / period) < 0.5) ? Oscillator.amplitude : -1.0 * Oscillator.amplitude
    }
    static let whiteNoise = { (time: Float) -> Float in
        return Oscillator.amplitude * Float.random(in: -1...1)
    }
}
