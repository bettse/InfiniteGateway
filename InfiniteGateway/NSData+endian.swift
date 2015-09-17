//
//  NSData+endian.swift
//  DIMP
//
//  Created by Eric Betts on 6/27/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

extension NSData {
    
    public var bigEndianUInt32: NSData {
        let swappedKey = NSMutableData()
        let count = (self.length/sizeof(UInt32))
        for i in 0..<count {
            var temp : UInt32 = 0
            self.getBytes(&temp, range: NSMakeRange(i*sizeof(UInt32), sizeof(UInt32)))
            var swap = temp.bigEndian
            swappedKey.appendBytes(&swap, length: sizeof(UInt32))
        }
        return NSData(data: swappedKey)
    }
    
    public var littleEndianUInt32: NSData {
        let swappedKey = NSMutableData()
        let count = (self.length/sizeof(UInt32))
        for i in 0..<count {
            var temp : UInt32 = 0
            self.getBytes(&temp, range: NSMakeRange(i*sizeof(UInt32), sizeof(UInt32)))
            var swap = temp.littleEndian
            swappedKey.appendBytes(&swap, length: sizeof(UInt32))
        }
        return NSData(data: swappedKey)
    }
    
    public var negation: NSData {
        let result = NSMutableData(data: self)
        let resultBytes = UnsafeMutablePointer<UInt8>(result.mutableBytes)
        for i in 0..<result.length {
            resultBytes[i] = ~resultBytes[i]
        }
        return NSData(data: result)
    }
    
    public var reverse: NSData {
        let result = NSMutableData(data: self)
        let resultBytes = UnsafeMutablePointer<UInt8>(result.mutableBytes)
        for i in 0..<result.length {
            resultBytes[i] = resultBytes[i].reverse
        }
        return NSData(data: result)
    }
    
}