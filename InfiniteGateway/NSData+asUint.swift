//
//  NSData+asUint.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 3/9/17.
//  Copyright © 2017 Eric Betts. All rights reserved.
//

import Foundation

extension Data {
    init(fromUInt16: UInt16) {
        var v : UInt16 = fromUInt16
        self = withUnsafePointer(to: &v) {
            Data(bytes: UnsafePointer($0), count: MemoryLayout.size(ofValue: v))
        }
    }
    
    init(fromUInt32: UInt32) {
        var v : UInt32 = fromUInt32
        self = withUnsafePointer(to: &v) {
            Data(bytes: UnsafePointer($0), count: MemoryLayout.size(ofValue: v))
        }
    }
    
    // ------

    mutating func replaceUInt8(_ offset: Int, value: UInt8) {
        let size = MemoryLayout.size(ofValue: value)
        let range = offset..<offset+size
        let data = Data([value])
        self.replaceSubrange(range, with: data)
    }
    
    mutating func replaceUInt16(_ offset: Int, value: UInt16) {
        let size = MemoryLayout.size(ofValue: value)
        let range = offset..<offset+size
        let data = Data(fromUInt16: value)
        self.replaceSubrange(range, with: data)
    }
    
    mutating func replaceUInt32(_ offset: Int, value: UInt32) {
        let size = MemoryLayout.size(ofValue: value)
        let range = offset..<offset+size
        let data = Data(fromUInt32: value)
        self.replaceSubrange(range, with: data)
    }
    
    // ------
    var uint8: UInt8 {
        get {
            return ([UInt8](self))[0]
        }
    }


    var uint16: UInt16 {
        get {
            let result = self.withUnsafeBytes {
                return [UInt16](UnsafeBufferPointer(start: $0, count: self.count))
            }
            return result[0]
        }
    }
    
    var uint32: UInt32 {
        get {
            let result = self.withUnsafeBytes {
                return [UInt32](UnsafeBufferPointer(start: $0, count: self.count))
            }
            return result[0]
        }
    }

    var uint64: UInt64 {
        get {
            let result = self.withUnsafeBytes {
                return [UInt64](UnsafeBufferPointer(start: $0, count: self.count))
            }
            return result[0]
        }
    }
    
    var uuid: UUID? {
        get {
            return NSUUID(uuidBytes: [UInt8](self)) as UUID
        }
    }
}
