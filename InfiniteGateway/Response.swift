//
//  Response.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

class Response : Message {
    enum Status : UInt8 {
        case success = 0x00
        case missingToken = 0x80
        case unsupportedToken = 0x82
        case readFail = 0x83
        case writeFail = 0x84
        case status86 = 0x86
        case unknown = 0xff
    }
    
    let sequenceIdIndex = 0
    let paramsIndex = 1
    
    var sequenceId : UInt8 = 0
    var params : Data
    
    var command : Command {
        get {
            return Message.archive[sequenceId]!
        }
    }
    
    var type : CommandType {
        get {
            return command.type
        }
    }
    
    override var description : String {
        let me = String(describing: type(of: self))
        return "\(me) for \(command)"
    }
    
    static func parse(_ data: Data) -> Response {
        let sequenceIdIndex = 0
        let command = Message.archive[data[sequenceIdIndex]]!
        let responseClass : Response.Type = command.responseClass
        return responseClass.init(data: data)
    }
    
    required init(data: Data) {
        self.params = data.subdata(in: paramsIndex..<data.count)
        super.init()
        sequenceId = data[sequenceIdIndex]        
    }
}

class AckResponse : Response {}

class StatusResponse : Response {
    let statusIndex = 1
    var status : Status
    
    override var description : String {
        let me = String(describing: type(of: self))
        return "\(me)(\(status)) for \(command)"
    }
    
    required init(data: Data) {
        status = Status(rawValue: data[statusIndex]) ?? .unknown
        super.init(data: data)
    }
}

class ActivateResponse : Response {}

class TagIdResponse : StatusResponse {
    let tagIdIndex = 2
    var nfcIndex : UInt8  {
        get {
            if let command = command as? TagIdCommand {
                return command.nfcIndex
            }
            return 0
        }
    }
    
    override var description : String {
        let me = String(describing: type(of: self))
        return "\(me)(\(tagId.toHexString())) for \(command)"
    }
    
    var tagId : Data
    
    required init(data: Data) {        
        tagId = data.subdata(in: tagIdIndex..<data.count)
        super.init(data: data)
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
    
    override var description : String {
        let me = String(describing: type(of: self))
        return "\(me)(\(details)) for \(command)"
    }
    
    required init(data: Data) {
        super.init(data: data)
        for i in stride(from: 0, to: params.count, by: 2) {
            let led : LedPlatform = LedPlatform(rawValue: params[i+platformOffset].high_nibble) ?? .none
            let nfc = params[i+nfcIndexOffset].low_nibble
            let sak : Sak = Sak(rawValue: params[i+sakOffset]) ?? .unknown
            details.append(Detail(nfcIndex: nfc, platform: led, sak: sak))
        }        
    }
}

class ReadResponse : StatusResponse {
    let blockDataIndex = 2
    var blockData : Data = Data()
    
    //Delegates for easier access
    var sectorNumber : UInt8  {
        get {
            if let command = command as? ReadCommand {
                return command.sectorNumber
            }
            return 0
        }
    }    
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
    
    override var description : String {
        let me = String(describing: type(of: self))
        return "\(me)(\(blockData.toHexString())) for \(command)"
    }
    
    required init(data: Data) {
        super.init(data: data)
        if (status == .success) {
            blockData = data.subdata(in: blockDataIndex..<data.count)
        }
    }
}

//Contains next scrambled value in PRNG
class NextResponse : Response {
    let scrambledIndex = 1
    var value : UInt64 = 0
    
    required init(data: Data) {
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
}

class SeedResponse : Response {}
