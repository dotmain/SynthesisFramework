//
//  SynthesisNode.swift
//  Synthesis
//
//  Created by m4m4 on 06.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
//
 
import Foundation
import Combine

public let kActiveBufferCount = 4
public let kSamplesPerBuffer = 4096 + 1024
public let kSamplesRate = 16000

public typealias SynthesisNodeCompletionHandler = () -> Void

public protocol Player {
    func scheduleBuffer(_ buffer: SynthesisBuffer, completionHandler: SynthesisNodeCompletionHandler?)
}

public typealias SynthesisPlayerCompletionHandler = () -> Void

public class SynthethisPlayer: Player {
    
//    public let publisher = PassthroughSubject<SynthesizedBuffer, Never>()
//    private var cancel: AnyCancellable?
    private let global: DispatchQueue = DispatchQueue(label: "com.mainvolume.dispatch")
    private let rq: DispatchQueue = DispatchQueue(label: "com.mainvolume.synthesis")
    private var semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    private var availableBuffers: [SynthesisBuffer] = []
    private var completionSignal: SynthesisPlayerCompletionHandler?
    
    public init() { }
    
    public func scheduleBuffer(_ buffer: SynthesisBuffer, completionHandler: SynthesisPlayerCompletionHandler? = nil) {
        global.async { [weak self] in
            self?.handleBuffer(buffer: buffer, completionHandler: completionHandler)
        }
    }
    
    private func handleBuffer(buffer: SynthesisBuffer, completionHandler: SynthesisPlayerCompletionHandler? = nil) {
        addBuffer(buffer)
        completionSignal = completionHandler
    }
    
    public func acquireBuffer() -> SynthesisBuffer? {
        completionSignal?()
        let _ = semaphore.wait(timeout: .distantFuture)
        var available: SynthesisBuffer?
        rq.sync{ [weak self] in
            guard let c = self?.availableBuffers.count, c > 0 else { return }
            available = self?.availableBuffers.remove(at: 0)
        }
        return available
    }
    
    public func addBuffer(_ buffer: SynthesisBuffer) {
        
        rq.async { [weak self] in
            self?.availableBuffers.append(buffer)
            self?.semaphore.signal()
        }
    }
    
    public func prime() {
        rq.async { [weak self] in
            self?.semaphore.signal()
        }
    }
}


public var onOff = true

public final class SynthesisNode {
    
    private (set) var format: SynthesisFormat
    private var que: SynthesiPCMBufferQueue?
    private let playbackQueue = DispatchQueue(label: "com.mainvolume.synthesis")
    private let bufferQue = DispatchQueue(label: "com.mainvolume.synthesis")
    private var play = true
    init(_ format: SynthesisFormat) {
        self.format = format
    }
    
    func initiaiteBuffers(_ player: Player) {
        
        bufferQue.async { [weak self, format] in
            let que = self?.createBuffers(format: format)
            que?.prime()
            self?.playbackQueue.async {
                while let audioBuffer = que?.acquireBuffer() {
                    player.scheduleBuffer(audioBuffer) {
                        que?.releaseBuffer(audioBuffer)
                    }
                }
                print( "all done. shutting down." )
            }
        }
       
       
    }
    

    
    private func createBuffers(format: SynthesisFormat) -> SynthesiPCMBufferQueue {
        var sampleTime = 0
        let que = SynthesiPCMBufferQueue(audioFormat: format, bufferCount: kActiveBufferCount, bufferLength: kSamplesPerBuffer) { audioBuffer in
             let ø = audioBuffer.fillPCMBuffer(withBlock:
                Bool.random() ?
                    Wave.makeWavesBlocks(sr: Int(format.sampleRate),
                    cc: ParameterType(format.channelCount),
                    length: kSamplesPerBuffer,
                    time: kActiveBufferCount)
                    :
                Wave.makeWavesBlocks(sr: Int(format.sampleRate),
                                     freq: ParameterType(Int.random(in: 16...432)),
                                     cc: ParameterType(format.channelCount)),
                                        atStartSample: sampleTime)
            sampleTime += Int(audioBuffer.capacity)
            return ø
        }
        return que
    }
    
    
    private static func fillFloats(floats: UnsafeMutablePointer<Float>, withSignal signal: Signal, ofLength length: Int, startingAtSample startSample: Int) {
        for i in 0..<length {
            floats[i] = signal(startSample + i)
        }
    }
    
    private static func fillInts16(ints: UnsafeMutablePointer<Int16>, withSignal signal: Signal, ofLength length: Int, startingAtSample startSample: Int) {
        for i in 0..<length {
            ints[i] = Int16(signal(startSample + i))
        }
    }
    
    private static func fillInts32(ints: UnsafeMutablePointer<Int32>, withSignal signal: Signal, ofLength length: Int, startingAtSample startSample: Int) {
        for i in 0..<length {
            ints[i] = Int32(signal(startSample + i))
        }
    }
    
    deinit {
        print("[ SYNTHESIS ] : [ DEINIT NODE ]")
    }
}






