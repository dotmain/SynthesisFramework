//
//  File.swift
//  
//
//  Created by .main on 2021-02-11.
//
 
import  Foundation

public class SignalSynth {
    
    // MARK: Private Properties
    private enum Waveform: Int, CaseIterable {
        case sine, triangle, sawtooth, square, whiteNoise
    }
    private let sampleRate: OscillationType
    private let delta: OscillationType
    private var time: OscillationType = 0
    private(set) var signal: OscillationSignal
    private var value: OscillationType { signal(self.time) }
   
    // MARK: Init
    public init(sampleRate: OscillationType,
                signal: @escaping OscillationSignal = SignalOscillator.sawtooth) {
        self.sampleRate = sampleRate
        delta = 1.0 / sampleRate
        self.signal = signal
    }
    
    // MARK: Private Functions
    private func setWaveformTo(_ signal: @escaping OscillationSignal) {
        self.signal = signal
    }
    
    // MARK: Public Functions
    public func updateOscillatorWaveform() {
        let waveform = Waveform(rawValue: Waveform.allCases.randomElement()?.rawValue ?? 0)
        switch waveform {
        case .sine: setWaveformTo(SignalOscillator.sine)
        case .triangle: setWaveformTo(SignalOscillator.triangle)
        case .sawtooth: setWaveformTo(SignalOscillator.sawtooth)
        case .square: setWaveformTo(SignalOscillator.square)
        case .whiteNoise: setWaveformTo(SignalOscillator.whiteNoise)
        case .none:
            print("none")
        }
    }
   
    public func setSynthParametersFrom() {
        SignalOscillator.amplitude = OscillationType.random(in: 0.0...1.0)
        SignalOscillator.frequency = OscillationType.random(in: 0...1024) + 32
        let amplitudePercent = Int(SignalOscillator.amplitude * 100)
        let frequencyHertz = Int(SignalOscillator.frequency)
        print("Frequency: \(frequencyHertz) Hz  Amplitude: \(amplitudePercent)%")
    }
    
    func buffer(length: OscillationType) -> [OscillationType] {
        let l = Int(length)
        return (0...l).map({ x in
            time += delta
            return value
        })
    }
}
