//
//  Command.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation


class Command : Message {
    let typeIndex = 0
    let sequenceIdIndex = 1
    let paramsIndex = 2

    static var sequenceGenerator = (1..<UInt8.max-1).makeIterator()
    static var nextSequence : UInt8 {
        get {
            if let next = sequenceGenerator.next() {
                return next
            }
            //Implicitly else
            sequenceGenerator = (1..<UInt8.max-1).makeIterator()
            return 0
        }
    }
    
    override var description : String {
        let me = String(describing: type(of: self))
        return "\(me) \(params.toHexString())"
    }
    
    var type : CommandType = .unset
    var responseClass : Response.Type = AckResponse.self
    var sequenceId : UInt8 = 0
    var params : Data = Data()

    init(commandType: CommandType) {
        sequenceId = Command.nextSequence
        super.init()
        Message.archive[sequenceId] = self
        self.type = commandType
    }
    
    convenience init(commandType: CommandType, params: Data) {
        self.init(commandType: commandType)
        self.params = params
    }
    
    //Parseing from NSData
    init(data: Data) {
        type = Message.CommandType(rawValue: data[typeIndex]) ?? .unset
        sequenceId = data[sequenceIdIndex]
        params = data.subdata(in: paramsIndex..<data.count)
    }

    func serialize() -> Data {
        var data = Data()
        data.append(Data([type.rawValue]))
        data.append(Data([sequenceId]))
        data.append(params)
        return data
    }
}

class ActivateCommand : Command {
    init() {
        super.init(commandType: .activate)
        responseClass = ActivateResponse.self
        params = PortalDriver.magic
    }
}

class SeedCommand : Command {
    init() {
        super.init(commandType: .seed)
        responseClass = SeedResponse.self
        params = Data(bytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    }
}

class NextCommand : Command {
    init() {
        super.init(commandType: .next)
        responseClass = NextResponse.self
    }
}

class PresenceCommand : Command {
    init() {
        super.init(commandType: .presence)
        responseClass = PresenceResponse.self
    }
}

class TagIdCommand : Command {
    var nfcIndex : UInt8
    init(nfcIndex: UInt8) {
        self.nfcIndex = nfcIndex
        super.init(commandType: .tagId)
        responseClass = TagIdResponse.self
        params = Data(bytes: [nfcIndex])
    }
}

class BlockCommand : Command {
    var nfcIndex : UInt8
    var sectorNumber : UInt8
    var blockNumber : UInt8
    
    override var description : String {
        let me = String(describing: type(of: self))
        return "\(me)(nfcIndex: \(nfcIndex), sectorNumber: \(sectorNumber), blockNumber: \(blockNumber))"
    }
    
    init(nfcIndex: UInt8, sectorNumber: UInt8, blockNumber: UInt8) {
        self.nfcIndex = nfcIndex
        self.sectorNumber = sectorNumber
        self.blockNumber = blockNumber
        super.init(commandType: .read)
        params = Data(bytes: [nfcIndex, sectorNumber, blockNumber])
    }
    
    convenience init(nfcIndex: Int, sectorNumber: Int, blockNumber: Int) {
        self.init(nfcIndex: UInt8(nfcIndex), sectorNumber: UInt8(sectorNumber), blockNumber: UInt8(blockNumber))
    }
    
    convenience init(nfcIndex: UInt8, sectorNumber: Int, blockNumber: Int) {
        self.init(nfcIndex: UInt8(nfcIndex), sectorNumber: UInt8(sectorNumber), blockNumber: UInt8(blockNumber))
    }
    
    convenience init(command: BlockCommand) {
        self.init(nfcIndex: command.nfcIndex, sectorNumber: command.sectorNumber, blockNumber: command.blockNumber)
    }
}

class ReadCommand : BlockCommand {
    override init(nfcIndex: UInt8, sectorNumber: UInt8, blockNumber: UInt8) {
        super.init(nfcIndex: nfcIndex, sectorNumber: sectorNumber, blockNumber: blockNumber)
        responseClass = ReadResponse.self
        self.type = .read
    }
}

class WriteCommand : BlockCommand {
    var blockData : Data
    
    init(nfcIndex: UInt8, sectorNumber: UInt8, blockNumber: UInt8, blockData: Data) {
        self.blockData = blockData
        super.init(nfcIndex: nfcIndex, sectorNumber: sectorNumber, blockNumber: blockNumber)
        responseClass = StatusResponse.self
        self.type = .read
        
        //Params set to [nfcIndex, sectorNumber, blockNumber] by parent class
        params.append(blockData)
    }
    
    convenience init(nfcIndex: UInt8, sectorNumber: UInt8, blockNumber: Int, blockData: Data) {
        self.init(nfcIndex: nfcIndex, sectorNumber: sectorNumber, blockNumber: UInt8(blockNumber), blockData: blockData)
    }
}

