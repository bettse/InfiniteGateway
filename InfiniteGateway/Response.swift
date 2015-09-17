//
//  Response.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

class Response : Message {
    let corrolationIdIndex = 0
    var corrolationId : UInt8 = 0

    //lol delegate
    var type : commandType {
        get {
            return command.type
        }
    }
    
    var command : Command {
        get {
            return (Message.archive[corrolationId] as! Command)
        }
    }
    
    init(data: NSData) {
        super.init()
        data.getBytes(&corrolationId, range: NSMakeRange(corrolationIdIndex, sizeof(UInt8)))
        
    }
    
    static func parse(data: NSData) -> Response {
        let r : Response = Response(data: data)
        switch r.command.type {
        case .Activate:
            return ActivateResponse(data: data)
        case .TagId:
            return TagIdResponse(data: data)
        case .Presence:
            return PresenceResponse(data: data)
        case .Read:
            return ReadResponse(data: data)
        case .Write:
            return WriteResponse(data: data)
        case .LightOn:
            return LightOnResponse(data: data)
        case .LightFade:
            return LightFadeResponse(data: data)
        case .LightFlash:
            return LightFlashResponse(data: data)
        case .Seed:
            return SeedResponse(data: data)
        case .Next:
            return NextResponse(data: data)
        }
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(type.desc()))"
    }
}

class ActivateResponse : Response {
    var params : NSData
    let paramsIndex = 1
    
    override init(data: NSData) {
        params = data.subdataWithRange(NSMakeRange(paramsIndex, data.length - paramsIndex))
        super.init(data: data)
    }
}

class TagIdResponse : Response {
    let tagIdIndex = 2
    var nfcIndex : UInt8  {
        get {
            if let command = command as? TagIdCommand {
                return command.nfcIndex
            }
            return 0
        }
    }
    var tagId : NSData
    
    override init(data: NSData) {
        tagId = data.subdataWithRange(NSMakeRange(tagIdIndex, data.length - tagIdIndex))
        super.init(data: data)        
    }

    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(NFC #\(nfcIndex): \(tagId))"
    }
}


class PresenceResponse : Response {
    var details = Dictionary<Message.LedPlatform, Array<UInt8>>()
    
    override init(data: NSData) {
        let bytes = UnsafePointer<UInt8>(data.bytes)
        for i in 1..<data.length {
            if (bytes[i] != 0x09) {
                let led = LedPlatform(rawValue: bytes[i].high_nibble) as LedPlatform!
                let nfc = bytes[i].low_nibble
                details[led] = details[led] ?? [UInt8]() //Define if not already defined
                details[led]!.append(nfc)
            }
        }
        super.init(data: data)
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(details))"
    }
    
    func asHex(value : UInt8) -> String {
        return "0x\(String(value, radix:0x10))"
    }
    
}

class ReadResponse : Response {
    let blockDataIndex = 2

    var blockData : NSData
    
    //Delegates for easier access
    var blockNumber : UInt8  {
        get {
            if let command = command as? ReadCommand {
                return command.blockNumber
            }
            return 0
        }
    }
    var nfcIndex : UInt8  {
        get {
            if let command = command as? ReadCommand {
                return command.nfcIndex
            }
            return 0
        }
    }
    
    override init(data: NSData) {
        blockData = data.subdataWithRange(NSMakeRange(blockDataIndex, data.length-blockDataIndex))
        super.init(data: data)
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(Platform \(nfcIndex) block \(blockNumber): \(blockData))"
    }
}

class SeedResponse : Response {
    
}

//Contains next scrambled value in PRNG
class NextResponse : Response {
    let scrambledIndex = 1
    var value : UInt64 = 0
    
    override init(data: NSData) {
        var scrambled : UInt64 = 0
        data.getBytes(&scrambled, range: NSMakeRange(scrambledIndex, sizeof(scrambled.dynamicType)))
        super.init(data: data)
        value = descramble(scrambled.bigEndian)
    }

    func descramble(input: UInt64) -> UInt64 {
        var scrambled : UInt64 = input
        var result : UInt64 = 0
        var mask : UInt64 = 0x5517999cd855aa71
    
        for _ in 0..<64 {
            if ((mask & 1) == 1) {
                result = result << 1;
                result |= (scrambled & 1);
            }
            scrambled = scrambled >> 1;
            mask = mask >> 1;
        }
        return result;
    }
    
    override var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me): 0x\(String(value, radix:0x10))"
    }

}

class WriteResponse : Response {

}

class LightOnResponse : Response {
}

class LightFadeResponse : Response {
}

class LightFlashResponse : Response {
}

