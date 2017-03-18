//
//  Message.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

//Parent class of Command, Response, and Update


//CustomStringConvertible make the 'description' method possible
class Message : CustomStringConvertible {
    enum CommandType : UInt8 {
        case activate = 0x80
        case seed = 0x81
        case next = 0x83
        case lightSet = 0x90
        case lightFade = 0x92
        case lightFlash = 0x93
        case light95 = 0x95
        case light96 = 0x96
        case light97 = 0x97
        case light99 = 0x99
        case presence = 0xA1
        case read = 0xA2
        case write = 0xA3
        case tagId = 0xB4
        case a4 = 0xa4
        case a5 = 0xa5
        case a6 = 0xa6
        case a7 = 0xa7
        case b1 = 0xb1
        case b8 = 0xb8
        case b9 = 0xb9
        case be = 0xbe
        case c0 = 0xc0
        case c1 = 0xc1
        case c2 = 0xc2
        case unset = 0xff
        func desc() -> String {
            return String(describing: self)
        }
    }
    enum LedPlatform : UInt8 {
        case all = 0
        case hex = 1
        case left = 2
        case right = 3
        case none = 0xFF
        func desc() -> String {
            return String(describing: self)
        }
    }
    
    enum Sak : UInt8 {
        case mifareUltralight = 0x00
        case mifareTNP3xxx = 0x01
        case mifareClassic1k = 0x08
        case mifareMini = 0x09
        case mifareClassic4k = 0x18
        case mifareDesFire = 0x20
        case unknown = 0xFF //Not standard
    }
    
    static var archive = [UInt8: Message]()
    
    var description: String {
        return String(describing: self)
    }
}
