//
//  LightCommand.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 3/17/17.
//  Copyright © 2017 Eric Betts. All rights reserved.
//

import Foundation
import AppKit

class PlatformCommand : Command {
    var ledPlatform : LedPlatform
    init(ledPlatform: LedPlatform) {
        self.ledPlatform = ledPlatform
        super.init(commandType: .unset)
        params = Data(bytes: [ledPlatform.rawValue])
    }
}

class LightSetCommand : Command {
    var ledPlatform : LedPlatform
    var red : UInt8, green: UInt8, blue : UInt8
    
    init(ledPlatform: LedPlatform, red : UInt8, green: UInt8, blue : UInt8) {
        self.ledPlatform = ledPlatform
        self.red = red
        self.green = green
        self.blue = blue
        super.init(commandType: .lightSet)
        params = Data(bytes: [ledPlatform.rawValue, red, green, blue])
    }
    
    convenience init(ledPlatform: LedPlatform, red : Int, green: Int, blue : Int) {
        self.init(ledPlatform: ledPlatform, red: UInt8(red), green: UInt8(green), blue: UInt8(blue))
    }
    
    convenience init(ledPlatform: LedPlatform, color : NSColor) {
        var r : UInt8 = 0, g: UInt8 = 0, b : UInt8 = 0
        let scale : CGFloat = CGFloat(UInt8.max)
        if let calibratedColor : NSColor = color.usingColorSpaceName(NSCalibratedRGBColorSpace) {
            r = UInt8(Int(calibratedColor.redComponent * scale))
            g = UInt8(Int(calibratedColor.greenComponent * scale))
            b = UInt8(Int(calibratedColor.blueComponent * scale))
        }
        
        self.init(ledPlatform: ledPlatform, red: r, green: g, blue: b)
    }
}

class LightFadeCommand : Command {
    var ledPlatform : LedPlatform
    var red : UInt8, green: UInt8, blue : UInt8
    var speed : UInt8 = 0
    var count : UInt8 = 0 //Even to end on original color, odd to end on new color
    
    init(ledPlatform: LedPlatform, red : UInt8, green: UInt8, blue : UInt8, speed : UInt8, count: UInt8) {
        self.ledPlatform = ledPlatform
        self.red = red
        self.green = green
        self.blue = blue
        self.speed = speed
        self.count = count
        super.init(commandType: .lightFade)
        params = Data(bytes: [ledPlatform.rawValue, red, green, blue, speed, count])
    }
    
    convenience init(ledPlatform: LedPlatform, red : Int, green: Int, blue : Int, speed: Int, count: Int) {
        self.init(ledPlatform: ledPlatform, red: UInt8(red), green: UInt8(green), blue: UInt8(blue), speed: UInt8(speed), count: UInt8(count))
    }
    
    convenience init(ledPlatform: LedPlatform, color : NSColor, speed: UInt8, count: UInt8) {
        var r : UInt8 = 0, g: UInt8 = 0, b : UInt8 = 0
        let scale : CGFloat = CGFloat(UInt8.max)
        if let calibratedColor : NSColor = color.usingColorSpaceName(NSCalibratedRGBColorSpace) {
            r = UInt8(Int(calibratedColor.redComponent * scale))
            g = UInt8(Int(calibratedColor.greenComponent * scale))
            b = UInt8(Int(calibratedColor.blueComponent * scale))
        }
        
        self.init(ledPlatform: ledPlatform, red: r, green: g, blue: b, speed: speed, count: count)
    }
    
    convenience init(ledPlatform: LedPlatform, color : NSColor, speed: Int, count: Int) {
        self.init(ledPlatform: ledPlatform, color: color, speed: UInt8(speed), count: UInt8(count))
    }
    
}

class LightFlashCommand : Command {
    var ledPlatform : LedPlatform
    var red : UInt8, green: UInt8, blue : UInt8
    var timeNew : UInt8 = 0
    var timeOld : UInt8 = 0
    var count : UInt8 = 0
    
    init(ledPlatform: LedPlatform, red : UInt8, green: UInt8, blue : UInt8, timeNew : UInt8, timeOld : UInt8, count: UInt8) {
        self.ledPlatform = ledPlatform
        self.red = red
        self.green = green
        self.blue = blue
        self.timeNew = timeNew
        self.timeOld = timeOld
        self.count = count
        super.init(commandType: .lightFlash)
        params = Data(bytes: [ledPlatform.rawValue, red, green, blue, timeNew, timeOld, count])
    }
    
    convenience init(ledPlatform: LedPlatform, color : NSColor, timeNew : UInt8, timeOld : UInt8, count: UInt8) {
        var r : UInt8 = 0, g: UInt8 = 0, b : UInt8 = 0
        let scale : CGFloat = CGFloat(UInt8.max)
        if let calibratedColor : NSColor = color.usingColorSpaceName(NSCalibratedRGBColorSpace) {
            r = UInt8(Int(calibratedColor.redComponent * scale))
            g = UInt8(Int(calibratedColor.greenComponent * scale))
            b = UInt8(Int(calibratedColor.blueComponent * scale))
        }
        
        self.init(ledPlatform: ledPlatform, red: r, green: g, blue: b, timeNew: timeNew, timeOld: timeOld, count: count)
    }
    
}
