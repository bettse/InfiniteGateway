//
//  NSData+asUint.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 3/9/17.
//  Copyright © 2017 Eric Betts. All rights reserved.
//

import Foundation
//
//  NSData+asUint.swift
//  Solarbreeze
//
//  Created by Eric Betts on 5/28/16.
//  Copyright © 2016 Eric Betts. All rights reserved.
//

import Foundation

extension Data {
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
