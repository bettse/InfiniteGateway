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
    let corrolationIdIndex = 1
    let paramsIndex = 2

    static var corrolationGenerator = (1..<UInt8.max-1).makeIterator()
    static var nextSequence : UInt8 {
        get {
            if let next = corrolationGenerator.next() {
                return next
            }
            //Implicitly else
            corrolationGenerator = (1..<UInt8.max-1).makeIterator()
            return 0
        }
    }
    
    var type : CommandType = .unset
    var corrolationId : UInt8 = 0
    var params : Data = Data()

    init(commandType: CommandType) {
        corrolationId = Command.nextSequence
        super.init()
        Message.archive[corrolationId] = self
        self.type = commandType
    }
    
    convenience init(commandType: CommandType, params: Data) {
        self.init(commandType: commandType)
        self.params = params
    }
    
    //Parseing from NSData
    init(data: Data) {
        type = Message.CommandType(rawValue: data[typeIndex]) ?? .unset
        corrolationId = data[corrolationIdIndex]
        params = data.subdata(in: paramsIndex..<data.count)
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()))"
    }
    
    func serialize() -> Data {
        var data = Data()
        data.append(Data([type.rawValue]))
        data.append(Data([corrolationId]))
        data.append(params)
        return data
    }
}

class BlockCommand : Command {
    var nfcIndex : UInt8
    var sectorNumber : UInt8
    var blockNumber : UInt8
    
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
}

class ActivateCommand : Command {
    init() {
        super.init(commandType: .activate)
        params = PortalDriver.magic
    }
}

class SeedCommand : Command {
    init() {
        super.init(commandType: .seed)
        params = Data(bytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    }
}

class NextCommand : Command {
    init() {
        super.init(commandType: .next)
    }
}

class PresenceCommand : Command {
    init() {
        super.init(commandType: .presence)
    }
}

class TagIdCommand : Command {
    var nfcIndex : UInt8
    init(nfcIndex: UInt8) {
        self.nfcIndex = nfcIndex
        super.init(commandType: .tagId)
        params = Data(bytes: [nfcIndex])
    }
}

class ReadCommand : BlockCommand {
    override init(nfcIndex: UInt8, sectorNumber: UInt8, blockNumber: UInt8) {
        super.init(nfcIndex: nfcIndex, sectorNumber: sectorNumber, blockNumber: blockNumber)
        self.type = .read
    }
}

class WriteCommand : BlockCommand {
    var blockData : Data
    
    init(nfcIndex: UInt8, sectorNumber: UInt8, blockNumber: UInt8, blockData: Data) {
        self.blockData = blockData
        super.init(nfcIndex: nfcIndex, sectorNumber: sectorNumber, blockNumber: blockNumber)
        self.type = .read
        
        //Params set to [nfcIndex, sectorNumber, blockNumber] by parent class
        params.append(blockData)
    }
    
    convenience init(nfcIndex: UInt8, sectorNumber: UInt8, blockNumber: Int, blockData: Data) {
        self.init(nfcIndex: nfcIndex, sectorNumber: sectorNumber, blockNumber: UInt8(blockNumber), blockData: blockData)
    }
}

