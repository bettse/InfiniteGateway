//
//  UInt8+reverse.swift
//  DIMP
//
//  Created by Eric Betts on 6/27/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

extension UInt8 { 
    public var low_nibble: UInt8 {
        return (self & 0x0F) >> 0;
    }
    
    public var high_nibble: UInt8 {
        return (self & 0xF0) >> 4;
    }
}