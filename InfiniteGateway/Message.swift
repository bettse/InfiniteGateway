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
    enum commandType : UInt8 {
        case Activate = 0x80
        case Seed = 0x81
        case Next = 0x83
        case LightOn = 0x90
        case LightFade = 0x92
        case LightFlash = 0x93
        case Presence = 0xA1
        case Read = 0xA2
        case Write = 0xA3
        case TagId = 0xB4
        func desc() -> String {
            return String(self).componentsSeparatedByString(".").last!
        }
    }    
    enum LedPlatform : UInt8 {
        case All = 0
        case Hex = 1
        case Left = 2
        case Right = 3
        func desc() -> String {
            return String(self).componentsSeparatedByString(".").last!
        }
    }
    
    static var archive = [UInt8: Message]()
    
    var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)"
    }

}