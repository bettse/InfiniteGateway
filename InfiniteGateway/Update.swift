//
//  Update.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

//Sorry about having something call nfcIndexIndex; it was the blending of the two patterns
class Update : Message {
    let ledPlatformIndex = 0
    let nfcIndexIndex = 2
    let directionIndex = 3
    enum Direction : UInt8 {
        case arriving = 0
        case departing = 1
        func desc() -> String {
            return String(describing: self)
        }
    }
    
    //Setting defaults so I don't have to deal with '?' style variables yet
    var ledPlatform : LedPlatform = .none
    var nfcIndex : UInt8 = 0
    var direction : Direction = .arriving
    
    init(data: Data) {
        ledPlatform = Message.LedPlatform(rawValue: data[ledPlatformIndex])!
        nfcIndex = data[nfcIndexIndex]
        direction = Update.Direction(rawValue: data[directionIndex])!
    }
    
    override var description: String {
        let me = String(describing: self)
        return "\(me)(\(ledPlatform.desc()) \(nfcIndex) \(direction.desc()))"
    }
}
