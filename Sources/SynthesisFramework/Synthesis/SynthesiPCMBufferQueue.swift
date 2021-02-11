//  AudioEngine.swift
//  Synthesis
//
//  Created by m4m4 on 05.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
//
 
import Foundation

public typealias AVAudioFrameCount = Int

// Just to demonstrate, mixing doubles and floats for parameter and sample types, respectively
public typealias ParameterType = Double
public typealias SampleType = Float

public typealias SynthesisBuffer = SynthesisRawBuffer
public typealias SynthesizedBuffer = Data


public typealias Signal = (Int) -> SampleType

public func NullSignal(_: Int) -> SampleType {
    return 0
}

public protocol BufferQueueType {
    associatedtype BufferType
    var processor: (BufferType) -> Bool { get }
    func acquireBuffer() -> BufferType?
    func releaseBuffer(_: BufferType)
}


public class SynthesisRawBuffer: Identifiable {
    public let id: UUID = UUID()
    public var data: Array<Int16>
    public let format: SynthesisFormat
    public let capacity: AVAudioFrameCount
    
    init (format: SynthesisFormat, capacity: AVAudioFrameCount) {
        self.format = format
        self.capacity = capacity
        self.data =  Array(repeating: 0, count: Int(capacity))
    }
    
    public func fillPCMBuffer(withBlock block: Block, atStartSample startSample: Int) -> Bool {
        let channelCount = Int(format.channelCount)
        assert( channelCount == block.outputCount )
        let outputs = block.process([])
        for i in 0..<channelCount {
            fillrawFloats(withSignal: outputs[i], startingAtSample: startSample)
        }
        return true
    }
    
    private func fillrawFloats(withSignal signal: Signal, startingAtSample startSample: Int) {
        for i in 0..<capacity {
            guard let intValue = (signal(startSample + Int(i)) * 32767).toInt16() else {
                data[Int(i)] = 0
                continue
            }
            data[Int(i)] = intValue
        }
    }  
}

public final class SynthesiPCMBufferQueue: BufferQueueType {
    public typealias BufferType = SynthesisBuffer
    
    private let buffers: [BufferType]
    private var availableBuffers: [BufferType]
    private (set) public var processor: (BufferType) -> Bool
    private var semaphore: DispatchSemaphore
    public var synthesized: [BufferType] {
        return availableBuffers
    }
    
    public init(audioFormat: SynthesisFormat, bufferCount: Int, bufferLength: Int, processor bufferProcessor: @escaping (BufferType) -> Bool) {
        
        let allBuffers: [BufferType] = (0..<bufferCount).compactMap{ _ in
            return SynthesisRawBuffer(format: audioFormat, capacity: AVAudioFrameCount(kSamplesPerBuffer))
        }
        
        buffers = allBuffers
        availableBuffers = []
        
        processor = bufferProcessor
        semaphore = DispatchSemaphore(value: 0)
    }
    
    private var rq: DispatchQueue = DispatchQueue(label: "com.mainvolume.synthesis")
    
    public func acquireBuffer() -> BufferType? {
        let _ = semaphore.wait(timeout: .distantFuture)
        var available: BufferType?
        rq.sync{ [weak self] in
            guard let c = self?.availableBuffers.count, c > 0 else { return }
            available = self?.availableBuffers.remove(at: 0)
        }
        
        return available
    }
    
    public func releaseBuffer(_ buffer: BufferType) {
        
        rq.async { [weak self] in
            if self?.processor(buffer) == true {
                self?.availableBuffers.append(buffer)
            }
            self?.semaphore.signal()
        }
    }
    
    public func prime() {
        for buffer in buffers {
            releaseBuffer(buffer)
        }
    }
    
    deinit {
        print("[ SYNTHESIS ] : [ DEINIT QUE ]")
    }
    
}
