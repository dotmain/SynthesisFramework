//
//  Utilities.swift
//  FunctionalDSP
//
//  Created by Christopher Liscio on 2015-03-09.
//  Copyright (c) 2015 SuperMegaUltraGroovy, Inc. All rights reserved.
//
//  Created by m4m4 on 23.01.20.
//  Copyright © 2020 mainvolume. All rights reserved.
 
import Foundation
import Accelerate

func scale(x: inout [Float], a: inout Float) {
    vDSP_vsmul(x, 1, &a, &x, 1, vDSP_Length(x.count))
}

func scale(x: inout [Double], a:inout Double) {
    vDSP_vsmulD(x, 1, &a, &x, 1, vDSP_Length(x.count))
}

func zeros(count: Int) -> [Float] {
     return Array(repeating: 0, count: count)
}

func zeros(count: Int) -> [Double] {
    return Array(repeating: 0, count: count)
}

extension Float {
    func toInt16()-> Int16? {
        if (self > Float(Int16.min) && self < Float(Int16.max) && !self.isNaN) {
            return Int16(self)
        } else {
            return nil
        }
    }
}

