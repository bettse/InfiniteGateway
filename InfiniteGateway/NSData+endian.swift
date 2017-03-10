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
        var swappedData = Data(self)
        let sizeof = 4 // sizeof(UInt32)
        let chunks = self.count / sizeof
        for i in 0..<chunks {
            let offset = i * sizeof
            let temp = self.subdata(in: offset..<offset + sizeof).uint32.bigEndian
            swappedData.replaceUInt32(offset, value: temp)            
        }
        return swappedData
    }
    
    public var littleEndianUInt32: Data {
        var swappedData = Data(self)
        let sizeof = 4 // sizeof(UInt32)
        let chunks = self.count / sizeof
        for i in 0..<chunks {
            let offset = i * sizeof
            let temp = self.subdata(in: offset..<offset + sizeof).uint32.littleEndian
            swappedData.replaceUInt32(offset, value: temp)
        }
        return swappedData
    }
    
    public var negation: Data {
        return Data(self.map({ return ~$0 }))
    }
    
}
