//
//  NSData+asUint.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 3/9/17.
//  Copyright © 2017 Eric Betts. All rights reserved.
//

import Foundation

extension Data {
    init(value: UInt16) {
        var v : UInt16 = value
        self = withUnsafePointer(to: &v) {
            Data(bytes: UnsafePointer($0), count: MemoryLayout.size(ofValue: v))
        }
    }
    
    init(value: UInt32) {
        var v : UInt32 = value
        self = withUnsafePointer(to: &v) {
            Data(bytes: UnsafePointer($0), count: MemoryLayout.size(ofValue: v))
        }
    }

    
    var uint8: UInt8 {
        get {
            return ([UInt8](self))[0]
        }
    }


    var uint16: UInt16 {
        get {
            _ = self.withUnsafeBytes {
                return [UInt16](UnsafeBufferPointer(start: $0, count: self.count))
            }
            return 0
        }
    }
    
    var uint32: UInt32 {
        get {
            _ = self.withUnsafeBytes {
                return [UInt32](UnsafeBufferPointer(start: $0, count: self.count))
            }
            return 0
        }
    }

    var uint64: UInt64 {
        get {
            _ = self.withUnsafeBytes {
                return [UInt64](UnsafeBufferPointer(start: $0, count: self.count))
            }
            return 0
        }
    }
    
    
    var uuid: UUID? {
        get {
            return NSUUID(uuidBytes: [UInt8](self)) as UUID
        }
    }
}
