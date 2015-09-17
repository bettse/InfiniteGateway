//
//  UInt8+reverse.swift
//  DIMP
//
//  Created by Eric Betts on 6/27/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

extension UInt8 {
    public var reverse: UInt8 {
        var r : UInt8 = self
        r = (r & 0xF0) >> 4 | (r & 0x0F) << 4;
        r = (r & 0xCC) >> 2 | (r & 0x33) << 2;
        r = (r & 0xAA) >> 1 | (r & 0x55) << 1;
        return r;
    }
 
    public var low_nibble: UInt8 {
        return (self & 0x0F) >> 0;
    }
    
    public var high_nibble: UInt8 {
        return (self & 0xF0) >> 4;
    }
}