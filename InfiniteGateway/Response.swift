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
    
    let corrolationIdIndex = 0
    let paramsIndex = 1
    
    var corrolationId : UInt8 = 0
    var params : Data

    //lol delegate
    var type : CommandType {
        get {
            return command.type
        }
    }
    
    //IDEA: dictionary to map command type to command class and/or response class
    // or returning subclass that has been cast to base class    
    var command : Command {
        get {
            let baseCommand = (Message.archive[corrolationId] as! Command)
            return baseCommand
        }
    }
    
    required init(data: Data) {
        self.params = data.subdata(in: paramsIndex..<data.count)
        super.init()
        corrolationId = data[corrolationIdIndex]        
    }
    
    static func parse(_ data: Data) -> Response {
        let r : Response = Response(data: data)
        let responseClass : Response.Type = r.command.responseClass
        return responseClass.init(data: data)
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()): \(params.toHexString()))"
    }
}

class AckResponse : Response {}

class StatusResponse : Response {
    let statusIndex = 1
    var status : Status
    
    required init(data: Data) {
        status = Status(rawValue: data[statusIndex]) ?? .unknown
        super.init(data: data)
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(command): \(status))"
    }
}

class ActivateResponse : Response {
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(params.toHexString()))"
    }
}

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
    
    var tagId : Data
    
    required init(data: Data) {        
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
    
    required init(data: Data) {
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
    
    required init(data: Data) {
        super.init(data: data)
        if (status == .success) {
            blockData = data.subdata(in: blockDataIndex..<data.count)
        }
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        if (status == .success) {
            return "\(me)(index \(nfcIndex) sector \(sectorNumber) block \(blockNumber): \(blockData.toHexString()))"
        } else {
            return "\(me)(index \(nfcIndex) sector \(sectorNumber) block \(blockNumber): Error: \(status))"
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
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me): 0x\(String(value, radix:0x10))"
    }
}

class SeedResponse : Response {}
