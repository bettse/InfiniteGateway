//
//  NSColor+rgb.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 3/18/17.
//  Copyright © 2017 Eric Betts. All rights reserved.
//

import Foundation
import Cocoa

extension NSColor {
    
    public var redByte : UInt8 {
        let scale : CGFloat = CGFloat(UInt8.max)
        if let calibratedColor : NSColor = self.usingColorSpaceName(NSCalibratedRGBColorSpace) {
            return UInt8(Int(calibratedColor.redComponent * scale))
        }
        return 0
    }
    
    public var greenByte : UInt8 {
        let scale : CGFloat = CGFloat(UInt8.max)
        if let calibratedColor : NSColor = self.usingColorSpaceName(NSCalibratedRGBColorSpace) {
            return UInt8(Int(calibratedColor.greenComponent * scale))
        }
        return 0
    }
    
    public var blueByte : UInt8 {
        let scale : CGFloat = CGFloat(UInt8.max)
        if let calibratedColor : NSColor = self.usingColorSpaceName(NSCalibratedRGBColorSpace) {
            return UInt8(Int(calibratedColor.blueComponent * scale))
        }
        return 0
    }
}
