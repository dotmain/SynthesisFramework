//
//  AudioSynthesis.swift
//  SynthesisSample
//
//  Created by m4m4 on 06.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
//
 
import Foundation
public protocol AudioSynthesisDelegate: class {
    func outDataSynthesized(data:SynthesisBuffer)
}

public final class AudioSynthesis {
    
    let player = SynthethisPlayer()
    let format: SynthesisFormat
    let node: SynthesisNode
    private let global: DispatchQueue = DispatchQueue(label: "com.mainvolume.dispatch")
    public weak var delegate: AudioSynthesisDelegate?
    
    public init(ƒ: SynthesisFormat) {
        self.format = ƒ
        node = SynthesisNode(self.format)
        node.initiaiteBuffers(player)
    }
    
    public func synthesize(size: Int = kActiveBufferCount) {
        var count = size
        global.async { [weak self] in
            while let audioBuffer = self?.player.acquireBuffer(), count != 0 {
                self?.delegate?.outDataSynthesized(data: audioBuffer)
                count -= 1
            }
        }
    }
}

