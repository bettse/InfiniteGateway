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
    
    override init() {
        corrolationId = Command.nextSequence
        super.init()
        Message.archive[corrolationId] = self
    }

    init(commandType: CommandType) {
        self.type = commandType
        super.init()
    }
    
    init(commandType: CommandType, params: Data) {
        self.type = commandType
        self.params = params
        super.init()
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

class ActivateCommand : Command {
    override init() {
        super.init(commandType: .activate, params: PortalDriver.magic)
    }
}

class SeedCommand : Command {
    override init() {
        super.init(commandType: .seed)
        params = Data(bytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    }
}

class NextCommand : Command {
    override init() {
        super.init(commandType: .next)
    }
}

class PresenceCommand : Command {
    override init() {
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

class ReadCommand : Command {
    var nfcIndex : UInt8
    var blockNumber : UInt8

    init(nfcIndex: UInt8, block: UInt8) {
        self.nfcIndex = nfcIndex
        self.blockNumber = block
        super.init(commandType: .read)
        params = Data(bytes: [nfcIndex, 0x00, block])
    }
    
    convenience init(nfcIndex: UInt8, block: Int) {
        self.init(nfcIndex: nfcIndex, block: UInt8(block))
    }
}

class WriteCommand : Command {
    var nfcIndex : UInt8
    var sectorNumber : UInt8
    var blockNumber : UInt8
    var blockData : Data
    
    init(nfcIndex: UInt8, block: UInt8, blockData: Data) {
        self.nfcIndex = nfcIndex
        self.blockNumber = block
        self.sectorNumber = 0
        self.blockData = blockData
        super.init(commandType: .write)
        var temp : Data = Data(bytes: [nfcIndex, sectorNumber, blockNumber])
        temp.append(blockData)
        params = temp
    }
    
    convenience init(nfcIndex: UInt8, block: Int, blockData: Data) {
        self.init(nfcIndex: nfcIndex, block: UInt8(block), blockData: blockData)
    }
}

