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
            return String(describing: self).components(separatedBy: ".").last!
        }
    }

    
    //Setting defaults so I don't have to deal with '?' style variables yet
    var ledPlatform : LedPlatform = .none
    var nfcIndex : UInt8 = 0
    var direction : Direction = .arriving
    
    init(data: Data) {
        (data as NSData).getBytes(&ledPlatform, range: NSMakeRange(ledPlatformIndex, MemoryLayout<LedPlatform>.size))
        (data as NSData).getBytes(&nfcIndex, range: NSMakeRange(nfcIndexIndex, MemoryLayout<UInt8>.size))
        (data as NSData).getBytes(&direction, range: NSMakeRange(directionIndex, MemoryLayout<Direction>.size))
    }
    
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(ledPlatform.desc()) \(nfcIndex) \(direction.desc()))"
    }
}
