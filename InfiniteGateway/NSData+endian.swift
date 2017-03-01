//
//  NSData+endian.swift
//  DIMP
//
//  Created by Eric Betts on 6/27/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

extension Data {
    
    public var bigEndianUInt32: Data {
        let swappedKey = NSMutableData()
        let count = (self.count/MemoryLayout<UInt32>.size)
        for i in 0..<count {
            var temp : UInt32 = 0
            (self as NSData).getBytes(&temp, range: NSMakeRange(i*MemoryLayout<UInt32>.size, MemoryLayout<UInt32>.size))
            var swap = temp.bigEndian
            swappedKey.append(&swap, length: MemoryLayout<UInt32>.size)
        }
        return (NSData(data: swappedKey as Data) as Data)
    }
    
    public var littleEndianUInt32: Data {
        let swappedKey = NSMutableData()
        let count = (self.count/MemoryLayout<UInt32>.size)
        for i in 0..<count {
            var temp : UInt32 = 0
            (self as NSData).getBytes(&temp, range: NSMakeRange(i*MemoryLayout<UInt32>.size, MemoryLayout<UInt32>.size))
            var swap = temp.littleEndian
            swappedKey.append(&swap, length: MemoryLayout<UInt32>.size)
        }
        return (NSData(data: swappedKey as Data) as Data)
    }
    
    public var negation: Data {
        let result = NSData(data: self) as Data
        let resultBytes = UnsafeMutablePointer<UInt8>(result.mutableBytes)
        for i in 0..<result.count {
            resultBytes[i] = ~resultBytes[i]
        }
        return (NSData(data: result) as Data)
    }
    
}
