//
//  NSData+hex.swift
//  DIMP
//
//  Created by Eric Betts on 6/29/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

//https://gist.github.com/kristopherjohnson/ed2623e1b486a8262b12
extension NSData {
    
    /// Return hexadecimal string representation of NSData bytes
    @objc(kdj_hexadecimalString)
    public var hexadecimalString: NSString {
        var bytes = [UInt8](count: length, repeatedValue: 0)
        getBytes(&bytes, length: length)
        
        let hexString = NSMutableString()
        for byte in bytes {
            hexString.appendFormat("%02x", UInt(byte))
        }
        
        return NSString(string: hexString)
    }
    
    subscript(origin: Int) -> UInt8 {
        get {
            var result: UInt8 = 0;
            if (origin < self.length) {
                self.getBytes(&result, range: NSMakeRange(origin, 1))
            }
            return result
        }
    }
}