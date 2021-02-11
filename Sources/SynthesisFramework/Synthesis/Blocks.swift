//
//  Blocks.swift
//  FunctionalDSP
//
//  Created by Christopher Liscio on 4/14/15.
//  Copyright (c) 2015 SuperMegaUltraGroovy, Inc. All rights reserved.
//
//  Created by m4m4 on 05.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
//
 
import Foundation

// Inspired by Faust:
// http://faust.grame.fr/index.php/documentation/references/12-documentation/reference/48-faust-syntax-reference-art

/// A block has zero or more inputs, and produces zero or more outputs
protocol BlockType {
    associatedtype SignalType
    typealias Proc = ([SignalType]) -> ([SignalType])
    var inputCount: Int { get }
    var outputCount: Int { get }
    var process: Proc { get }
    init(inputCount: Int, outputCount: Int, process: @escaping Proc)
}


public struct Block: BlockType {
    typealias SignalType = Signal
    let inputCount: Int
    let outputCount: Int
    let process: Proc
    
    init(inputCount: Int, outputCount: Int, process: @escaping Proc) {
        self.inputCount = inputCount
        self.outputCount = outputCount
        self.process = process
    }
}


func identity(inputs: Int) -> Block {
    return Block(inputCount: inputs, outputCount: inputs, process: { $0 })
}

//
//   -block-----
//  =|=[A]=[B]=|=
//   -----------
//

/// Runs two blocks serially
func serial<B: BlockType>(lhs: B, rhs: B) -> B {
    return B(inputCount: lhs.inputCount, outputCount: rhs.outputCount) { inputs in
        return rhs.process(lhs.process(inputs))
    }
}

////
////   -block---
////  =|==[A]==|=
////  =|==[B]==|=
////   ---------
////
//
/// Runs two blocks in parallel
func parallel<B: BlockType>(lhs: B, rhs: B) -> B {
    let totalInputs = lhs.inputCount + rhs.inputCount
    let totalOutputs = lhs.outputCount + rhs.outputCount
    
    return B(inputCount: totalInputs, outputCount: totalOutputs, process: { inputs in
        var outputs: [B.SignalType] = []
        
        outputs += lhs.process(Array<B.SignalType>(inputs[0..<lhs.inputCount]))
        outputs += rhs.process(Array<B.SignalType>(inputs[lhs.inputCount..<lhs.inputCount+rhs.inputCount]))
        
        return outputs
    })
}
//
////
////   -block-------
////  =|=[A]=>-[B]-|-
////   -------------
////
//
///// Merges the outputs of the block on the left to the inputs of the block on the right
func merge<B: BlockType>(lhs: B, rhs: B) -> B where B.SignalType == Signal {
    return B(inputCount: lhs.inputCount, outputCount: rhs.outputCount, process: { inputs in
        let leftOutputs = lhs.process(inputs)
        var rightInputs: [Signal] = []

        let k = lhs.outputCount / rhs.inputCount
        for i in 0..<rhs.inputCount  {
            var inputsToSum = Array<B.SignalType>()
            for j in 0..<k {
                inputsToSum.append(leftOutputs[i+(rhs.inputCount*j)])
            }
            let summed = inputsToSum.reduce(NullSignal) { mix(s1: $0, s2: $1) }
            rightInputs.append(summed)
        }

        return rhs.process(rightInputs)
    })
}


//
////
////     -block-------
////    -|-[A]-<=[B]=|=
////     -------------
////
////

/// Split the block on the left, replicating its outputs as necessary to fill the inputs of the block on the right
func split<B: BlockType>(lhs: B, rhs: B) -> B {
    return B(inputCount: lhs.inputCount, outputCount: rhs.outputCount, process: { inputs in
        let leftOutputs = lhs.process(inputs)
        var rightInputs: [B.SignalType] = []
        
        // Replicate the channels from the lhs to each of the inputs
        
        let k = lhs.outputCount
        for i in 0..<rhs.inputCount {
            rightInputs.append(leftOutputs[i%k])
        }
        
        return rhs.process(rightInputs)
    })
}
//
//// MARK: Operators
//
// After
precedencegroup BlockPrecedence {
    associativity: left
}


infix operator |- : BlockPrecedence
infix operator -- : BlockPrecedence
infix operator -< : BlockPrecedence
infix operator >- : BlockPrecedence

// Parallel
func |- <B: BlockType>(lhs: B, rhs: B) -> B {
    return parallel(lhs: lhs, rhs: rhs)
}

// Serial
func -- <B: BlockType>(lhs: B, rhs: B) -> B {
    return serial(lhs: lhs, rhs: rhs)
}

// Split
func -< <B: BlockType>(lhs: B, rhs: B) -> B {
    return split(lhs: lhs, rhs: rhs)
}

// Merge
func >- <B: BlockType>(lhs: B, rhs: B) -> B where B.SignalType == Signal {
    return merge(lhs: lhs, rhs: rhs)
}
