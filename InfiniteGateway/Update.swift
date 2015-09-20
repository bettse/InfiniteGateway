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
        case Arriving = 0
        case Departing = 1
        func desc() -> String {
            return String(self).componentsSeparatedByString(".").last!
        }
    }

    
    //Setting defaults so I don't have to deal with '?' style variables yet
    var ledPlatform : LedPlatform = .None
    var nfcIndex : UInt8 = 0
    var direction : Direction = .Arriving
    
    init(data: NSData) {
        data.getBytes(&ledPlatform, range: NSMakeRange(ledPlatformIndex, sizeof(LedPlatform)))
        data.getBytes(&nfcIndex, range: NSMakeRange(nfcIndexIndex, sizeof(nfcIndex.dynamicType)))
        data.getBytes(&direction, range: NSMakeRange(directionIndex, sizeof(Direction)))
    }
    
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(ledPlatform.desc()) \(nfcIndex) \(direction.desc()))"
    }
}