//
//  Command.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import AppKit

class Command : Message {
    let typeIndex = 0
    let corrolationIdIndex = 1
    let paramsIndex = 2

    static var corrolationGenerator = (1..<UInt8.max-1).makeIterator()
    static var nextSequence : UInt8 {
        get {
            if let next = corrolationGenerator.next() {
                return next
            }
            //Implicitly else
            corrolationGenerator = (1..<UInt8.max-1).makeIterator()
            return 0
        }
    }
    
    var type : commandType = .activate
    var corrolationId : UInt8 = 0
    var params : Data = Data()
    
    override init() {
        corrolationId = Command.nextSequence
        super.init()
        Message.archive[corrolationId] = self
    }
    
    //Parseing from NSData
    init(data: Data) {
        type = Message.commandType(rawValue: data[typeIndex])!
        corrolationId = data[corrolationIdIndex]
        params = data.subdata(in: paramsIndex..<data.count)
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()))"
    }
    
    func serialize() -> Data {
        var data = Data()
        data.append(Data([type.rawValue]))
        data.append(Data([corrolationId]))
        data.append(params)
        return data
    }
}

class ActivateCommand : Command {
    override init() {
        super.init()
        type = .activate
        params = PortalDriver.magic
    }
}

class SeedCommand : Command {
    override init() {
        super.init()
        type = .seed
        params = Data(bytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    }
}

class NextCommand : Command {
    override init() {
        super.init()
        type = .next
    }
}

class PresenceCommand : Command {
    override init() {
        super.init()
        type = .presence
    }
}

class TagIdCommand : Command {
    var nfcIndex : UInt8
    init(nfcIndex: UInt8) {
        self.nfcIndex = nfcIndex
        super.init()
        type = .tagId
        params = Data(bytes: [nfcIndex])
    }
}

class ReadCommand : Command {
    var nfcIndex : UInt8
    var blockNumber : UInt8

    init(nfcIndex: UInt8, block: UInt8) {
        self.nfcIndex = nfcIndex
        self.blockNumber = block
        super.init()
        type = .read
        params = Data(bytes: [nfcIndex, 0x00, block])
    }
    
    convenience init(nfcIndex: UInt8, block: Int) {
        self.init(nfcIndex: nfcIndex, block: UInt8(block))
    }
}

class WriteCommand : Command {
    var nfcIndex : UInt8
    var blockNumber : UInt8
    var blockData : Data
    
    init(nfcIndex: UInt8, block: UInt8, blockData: Data) {
        self.nfcIndex = nfcIndex
        self.blockNumber = block
        self.blockData = blockData
        super.init()
        type = .write
        var temp : Data = Data(bytes: [nfcIndex, 0x00, block])
        temp.append(blockData)
        params = temp
    }
    
    convenience init(nfcIndex: UInt8, block: Int, blockData: Data) {
        self.init(nfcIndex: nfcIndex, block: UInt8(block), blockData: blockData)
    }
}

class LightOnCommand : Command {
    var ledPlatform : LedPlatform
    var red : UInt8, green: UInt8, blue : UInt8
    
    init(ledPlatform: LedPlatform, red : UInt8, green: UInt8, blue : UInt8) {
        self.ledPlatform = ledPlatform
        self.red = red
        self.green = green
        self.blue = blue
        super.init()
        type = .lightOn
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
        super.init()
        type = .lightOn
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
        super.init()
        type = .lightOn
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

