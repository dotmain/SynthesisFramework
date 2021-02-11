//
//  File.swift
//  
//
//  Created by .main on 2021-02-11.
//
 
import Foundation

public struct SignalOscillator {
    
    public static var amplitude: OscillationType = 1.0
    public static var frequency: OscillationType = 16000
    public static let sine = { (time: OscillationType) -> OscillationType in
        return SignalOscillator.amplitude * sin(OscillationType.pi * SignalOscillator.frequency * time)
    }
    public static let triangle = { (time: OscillationType) -> OscillationType in
        let period = 1.0 / OscillationType(Oscillator.frequency)
        let currentTime = fmod(OscillationType(time), period)
        let value = currentTime / period
        var result = 0.0
        if value < 0.25 {
            result = value * 4
        } else if value < 0.75 {
            result = 2.0 - (value * 4.0)
        } else {
            result = value * 4 - 4.0
        }
        return SignalOscillator.amplitude * OscillationType(result)
    }
    public static let sawtooth = { (time: OscillationType) -> OscillationType in
        let period = 1.0 / SignalOscillator.frequency
        let currentTime = fmod(Double(time), Double(period))
        
        return SignalOscillator.amplitude * ((OscillationType(currentTime) / period) * 2 - 1.0)
    }
    public static let square = { (time: OscillationType) -> OscillationType in
        let period = 1.0 / Double(Oscillator.frequency)
        let currentTime = fmod(Double(time), period)
        return ((currentTime / period) < 0.5) ? SignalOscillator.amplitude : -1.0 * SignalOscillator.amplitude
    }
    public static let whiteNoise = { (time: OscillationType) -> OscillationType in
        return SignalOscillator.amplitude * OscillationType.random(in: -1...1)
    }
}
