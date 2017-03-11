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
    
    init(data: Data) {
        super.init()
        corrolationId = data[corrolationIdIndex]
    }
    
    static func parse(_ data: Data) -> Response {
        let r : Response = Response(data: data)
        switch r.command.type {
        case .activate:
            return ActivateResponse(data: data)
        case .tagId:
            return TagIdResponse(data: data)
        case .presence:
            return PresenceResponse(data: data)
        case .read:
            return ReadResponse(data: data)
        case .write:
            return WriteResponse(data: data)
        case .lightOn:
            return LightOnResponse(data: data)
        case .lightFade:
            return LightFadeResponse(data: data)
        case .lightFlash:
            return LightFlashResponse(data: data)
        case .seed:
            return SeedResponse(data: data)
        case .next:
            return NextResponse(data: data)
        case .c0:
            return C0Response(data: data)
        }
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()))"
    }
}

class ActivateResponse : Response {
    var params : Data
    let paramsIndex = 1
    
    override init(data: Data) {
        params = data.subdata(in: paramsIndex..<data.count)
        super.init(data: data)
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(params))"
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
    var tagId : Data
    
    override init(data: Data) {
        tagId = data.subdata(in: tagIdIndex..<data.count)
        super.init(data: data)        
    }

    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(NFC #\(nfcIndex): \(tagId))"
    }
}


class PresenceResponse : Response {
    var details = Dictionary<Message.LedPlatform, Array<UInt8>>()
    
    override init(data: Data) {
        let bytes = [UInt8](data)
        for i in 1..<data.count {
            if (bytes[i] != 0x09) {
                let led = LedPlatform(rawValue: bytes[i].high_nibble) as LedPlatform!
                let nfc = bytes[i].low_nibble
                details[led!] = details[led!] ?? [UInt8]() //Define if not already defined
                details[led!]!.append(nfc)
            }
        }
        super.init(data: data)
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(details))"
    }
    
    func asHex(_ value : UInt8) -> String {
        return "0x\(String(value, radix:0x10))"
    }
    
}

class ReadResponse : Response {
    let blockDataIndex = 2

    var blockData : Data
    
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
    
    override init(data: Data) {
        blockData = data.subdata(in: blockDataIndex..<data.count)
        super.init(data: data)
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(Platform \(nfcIndex) block \(blockNumber): \(blockData.toHexString()))"
    }
}

class SeedResponse : Response {
    
}

//Contains next scrambled value in PRNG
class NextResponse : Response {
    let scrambledIndex = 1
    var value : UInt64 = 0
    
    override init(data: Data) {
        var scrambled : UInt64 = 0
        let start = data.subdata(in: scrambledIndex..<data.count)
        scrambled = start.uint64
        super.init(data: data)
        value = descramble(scrambled.bigEndian)
    }

    func descramble(_ input: UInt64) -> UInt64 {
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
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
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

class C0Response : Response {
    var params : Data
    let paramsIndex = 1
    
    override init(data: Data) {
        params = data.subdata(in: paramsIndex..<data.count)
        super.init(data: data)
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)[\(params.toHexString())]"
    }
}
