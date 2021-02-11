//
//  FunctionalDSP.swift
//  FunctionalDSP
//
//  Created by Christopher Liscio on 3/8/15.
//  Copyright (c) 2015 SuperMegaUltraGroovy, Inc. All rights reserved.
//
//  Created by m4m4 on 05.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
//
 
import Foundation
import Accelerate

// MARK: Basic Operations

public func scale(s:@escaping Signal, amplitude: ParameterType) -> Signal {
    return { i in
        return SampleType(s(i) * SampleType(amplitude))
    }
}

// MARK: Mixing

public func mix(s1:@escaping Signal, s2:@escaping Signal) -> Signal {
    return { i in
        return s1(i) + s2(i)
    }
}

public func mix(signals: [Signal]) -> Signal {
    return { i in
        return signals.reduce(SampleType(0)) { $0 + $1(i) }
    }
}

// MARK: Generators

///// Generate a sine wave
//public func sineWave(sampleRate: Int, frequency: ParameterType) -> Signal {
//    let phi = frequency / ParameterType(sampleRate)
//    return { i in
//        return SampleType(sin(2.0 * ParameterType(i) * phi * ParameterType(Double.pi)))
//    }
//}
//
//// MARK: Generators
//
///// Generate a some wave
//public func someWave(sampleRate: Int, frequency: ParameterType) -> Signal {
//    let phi = frequency / ParameterType(sampleRate)
//    return { i in
//        let amp = SampleType(cos(0.007 * phi * ParameterType(i - 1)))
//        return SampleType(sin(2.0 * ParameterType(i - 1) * phi * ParameterType(Double.pi))) * amp
//    }
//}
//
///// Simple white noise generator
//public func whiteNoise() -> Signal {
//    return { _ in
//        return SampleType(-1.0 + 2.0 * (SampleType(arc4random_uniform(UInt32(Int16.max))) / SampleType(Int16.max)))
//    }
//}

// MARK: Output

/// Read count samples from the signal starting at the specified index
public func getOutput(signal: Signal, index: Int, count: Int) -> [SampleType] {
    return [Int](index..<count).map { signal($0) }
}

// MARK: Filtering

public typealias FilterType = Double
public extension FilterType {
    static let Epsilon = Double.ulpOfOne
}

public struct PinkFilter {
    // Filter coefficients from jos: https://ccrma.stanford.edu/~jos/sasp/Example_Synthesis_1_F_Noise.html
    var b: [FilterType] = [0.049922035, -0.095993537, 0.050612699, -0.004408786];
    var a: [FilterType] = [1.000000000, -2.494956002, 2.017265875, -0.522189400];
    
    // The filter's "memory"
    public var w: [FilterType] = []
    
    public init() {}
}


var gFilt = PinkFilter()
public func pinkFilter(x: @escaping Signal) -> Signal {
    return filt(x: x, b: gFilt.b, a: gFilt.a, w: &gFilt.w)
}

public func filt(x:@escaping Signal,  b: [FilterType],  a: [FilterType], w: inout [FilterType]) -> Signal {
    let N = a.count
    let M = b.count
    let MN = max(N, M)
    let lw = MN - 1
    var b = b
    var a = a
    if w.count != lw {
        w = Array(repeating: FilterType(0), count: lw)
    }
    
    if b.count < MN {
        b = b + zeros(count: MN-b.count)
    }
    if a.count < MN {
        a = a + zeros(count: MN-a.count)
    }
    
    let norm = a[0]
    var rNorm = 1.0 / norm
    assert(norm > 0, "First element in A must be nonzero")
    if fabs(norm - 1.0) > FilterType.Epsilon {
        scale(x: &b, a: &rNorm)
    }
    
    if N > 1 {
        // IIR Filter Case
        if fabs(norm - 1.0) > FilterType.Epsilon {
            scale(x: &a, a: &rNorm)
        }

        return { [w] i in
            var w = w
            let xi = FilterType(x(i))
            let y = w[0] + (b[0] * xi)
            if ( lw > 1 ) {
                for j in 0..<(lw - 1) {
                    let r =  w[j+1] + (b[j+1] * xi)
                    let x = (a[j+1] * y)
                    w[j] = r - x
                }
                w[lw-1] = (b[MN-1] * xi) - (a[MN-1] * y)
            } else {
                w[0] = (b[MN-1] * xi) - (a[MN-1] * y)
            }
            return SampleType(y * 2.0)
        }
    } else {
        // FIR Filter Case
        if lw > 0 {
            return { [w] i in
                var w = w

                let xi = FilterType(x(i))
                let y = w[0] + b[0] * xi
                if ( lw > 1 ) {
                    for j in 0..<(lw - 1) {
                        w[j] = w[j+1] + (b[j+1] * xi)
                    }
                    w[lw-1] = b[MN-1] * xi;
                }
                else {
                    w[0] = b[1] * xi
                }
                return Float(y)
            }
        } else {
            // No delay
            return { i in Float(Double(x(i)) * b[0]) }
        }
    }
}


