//
//  SynthesisFormat.swift
//  Synthesis
//
//  Created by m4m4 on 23.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
//
 
public struct SynthesisFormat {
    let sampleRate: Int
    let channelCount: Int
    let length: Int
    public init(sr: Int, cc: Int, l:Int) {
        self.sampleRate = sr
        self.channelCount = cc
        self.length = l
    }
}
