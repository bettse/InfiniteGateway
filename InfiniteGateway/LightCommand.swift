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

class LightGetCommand : PlatformCommand {
    override init(ledPlatform: LedPlatform) {
        super.init(ledPlatform: ledPlatform)
        type = .lightGet
        /* 
         Because 'all' doesn't have any meaning when getting a single 
         light status, the platform numbers are all shifted down by one
        */
        params = Data(bytes: [ledPlatform.rawValue-1])
    }
}

class LightCommand : PlatformCommand {
    var red : UInt8, green: UInt8, blue : UInt8
    init(ledPlatform: LedPlatform, red : UInt8, green: UInt8, blue : UInt8) {
        // Set attributes of current class first
        self.red = red
        self.green = green
        self.blue = blue
        // construct parent class and override/modify its attributes
        super.init(ledPlatform: ledPlatform)
        params.append(Data(bytes: [red, green, blue]))
    }
    
    convenience init(ledPlatform: LedPlatform, red : Int, green: Int, blue : Int) {
        self.init(ledPlatform: ledPlatform, red: UInt8(red), green: UInt8(green), blue: UInt8(blue))
    }
    
    convenience init(ledPlatform: LedPlatform, color : NSColor) {        
        self.init(ledPlatform: ledPlatform, red: color.redByte, green: color.greenByte, blue: color.blueByte)
    }
}

class LightSetCommand : LightCommand {
    override init(ledPlatform: LedPlatform, red : UInt8, green: UInt8, blue : UInt8) {
        super.init(ledPlatform: ledPlatform, red: red, green: green, blue: blue)
        self.type = .lightSet
    }
}

class LightFadeCommand : LightCommand {
    var speed : UInt8 = 0
    var count : UInt8 = 0 //Even to end on original color, odd to end on new color
    
    init(ledPlatform: LedPlatform, red : UInt8, green: UInt8, blue : UInt8, speed : UInt8, count: UInt8) {
        super.init(ledPlatform: ledPlatform, red: red, green: green, blue: blue)
        self.type = .lightFade
        self.speed = speed
        self.count = count
        params.append(Data(bytes: [speed, count]))
    }
    
    convenience init(ledPlatform: LedPlatform, red : Int, green: Int, blue : Int, speed: Int, count: Int) {
        self.init(ledPlatform: ledPlatform, red: UInt8(red), green: UInt8(green), blue: UInt8(blue), speed: UInt8(speed), count: UInt8(count))
    }
    
    convenience init(ledPlatform: LedPlatform, color : NSColor, speed: UInt8, count: UInt8) {
        self.init(ledPlatform: ledPlatform, red: color.redByte, green: color.greenByte, blue: color.blueByte, speed: speed, count: count)
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
        self.init(ledPlatform: ledPlatform, red: color.redByte, green: color.greenByte, blue: color.blueByte, timeNew: timeNew, timeOld: timeOld, count: count)
    }
}
