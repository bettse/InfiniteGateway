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
    let paramsIndex = 1
    
    var corrolationId : UInt8 = 0
    var params : Data

    
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
        self.params = data.subdata(in: paramsIndex..<data.count)
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
        case .b1:
            return B1Response(data: data)
        case .b8:
            return B8Response(data: data)
        case .b9:
            return B9Response(data: data)
        case .c1:
            return C1Response(data: data)
        default:
            return r
        }
    }

    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()): \(params.toHexString()))"
    }
}

class ActivateResponse : Response {
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(params.toHexString()))"
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
        return "\(me)(NFC #\(nfcIndex): \(tagId.toHexString()))"
    }
}


struct Detail {
    var nfcIndex : UInt8 = 0
    var platform : Message.LedPlatform = .none
    var sak : Message.Sak = .unknown
}

class PresenceResponse : Response {
    // Pairs of bytes for each token
    let platformOffset = 0 // high nibble
    let nfcIndexOffset = 0 // low nibble
    let sakOffset = 1

    var details = Array<Detail>()
    
    override init(data: Data) {
        super.init(data: data)
        for i in stride(from: 0, to: params.count, by: 2) {
            let led : LedPlatform = LedPlatform(rawValue: params[i+platformOffset].high_nibble) ?? .none
            let nfc = params[i+nfcIndexOffset].low_nibble
            let sak : Sak = Sak(rawValue: params[i+sakOffset]) ?? .unknown
            details.append(Detail(nfcIndex: nfc, platform: led, sak: sak))
        }
        
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(details))"
    }
}

class ReadResponse : Response {
    let statusIndex = 1
    let blockDataIndex = 2
    var status : Status
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
        status = Status(rawValue: data[statusIndex]) ?? .unknown
        if (status == .success) {
            blockData = data.subdata(in: blockDataIndex..<data.count)
        } else {
            blockData = Data()
        }
        super.init(data: data)
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        if (status == .success) {
            return "\(me)(index \(nfcIndex) block \(blockNumber): \(blockData.toHexString()))"
        } else {
            return "\(me)(index \(nfcIndex) block \(blockNumber): Error: \(status))"
        }
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

class B1Response : Response {
    var nfcIndex : UInt8  {
        get {
            if let command = command as? B1Command {
                return command.nfcIndex
            }
            return 0
        }
    }
    
    var value2 : UInt8  {
        get {
            if let command = command as? B1Command {
                return command.value2
            }
            return 0
        }
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)[\(command.params.toHexString()): \(params.toHexString())]"
    }
}

class B8Response : Response {
    var value : UInt8  {
        get {
            if let command = command as? B8Command {
                return command.value
            }
            return 0
        }
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)[\(command.params.toHexString()): \(params.toHexString())]"
    }
}


class B9Response : Response {
    var value : UInt8  {
        get {
            if let command = command as? B9Command {
                return command.value
            }
            return 0
        }
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!    
        return "\(me)[\(command.params.toHexString()): \(params.toHexString())]"
    }
}


class C0Response : Response {
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)[\(params.toHexString())]"
    }
}

class C1Response : Response {
    var value : UInt8  {
        get {
            if let command = command as? C1Command {
                return command.value
            }
            return 0
        }
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)[\(params.toHexString())]"
    }
}

