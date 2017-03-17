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
    
    var type : commandType = .unset
    var corrolationId : UInt8 = 0
    var params : Data = Data()
    
    override init() {
        corrolationId = Command.nextSequence
        super.init()
        Message.archive[corrolationId] = self
    }
    
    //Parseing from NSData
    init(data: Data) {
        type = Message.commandType(rawValue: data[typeIndex])!
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
        super.init()
        type = .activate
        params = PortalDriver.magic
    }
}

class SeedCommand : Command {
    override init() {
        super.init()
        type = .seed
        params = Data(bytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    }
}

class NextCommand : Command {
    override init() {
        super.init()
        type = .next
    }
}

class PresenceCommand : Command {
    override init() {
        super.init()
        type = .presence
    }
}

class TagIdCommand : Command {
    var nfcIndex : UInt8
    init(nfcIndex: UInt8) {
        self.nfcIndex = nfcIndex
        super.init()
        type = .tagId
        params = Data(bytes: [nfcIndex])
    }
}

class ReadCommand : Command {
    var nfcIndex : UInt8
    var blockNumber : UInt8

    init(nfcIndex: UInt8, block: UInt8) {
        self.nfcIndex = nfcIndex
        self.blockNumber = block
        super.init()
        type = .read
        params = Data(bytes: [nfcIndex, 0x00, block])
    }
    
    convenience init(nfcIndex: UInt8, block: Int) {
        self.init(nfcIndex: nfcIndex, block: UInt8(block))
    }
}

class WriteCommand : Command {
    var nfcIndex : UInt8
    var blockNumber : UInt8
    var blockData : Data
    
    init(nfcIndex: UInt8, block: UInt8, blockData: Data) {
        self.nfcIndex = nfcIndex
        self.blockNumber = block
        self.blockData = blockData
        super.init()
        type = .write
        var temp : Data = Data(bytes: [nfcIndex, 0x00, block])
        temp.append(blockData)
        params = temp
    }
    
    convenience init(nfcIndex: UInt8, block: Int, blockData: Data) {
        self.init(nfcIndex: nfcIndex, block: UInt8(block), blockData: blockData)
    }
}


class B1Command : Command {
    var nfcIndex : UInt8 = 0
    var value2 : UInt8 = 0
    
    init(nfcIndex: UInt8, value2: UInt8) {
        super.init()
        self.nfcIndex = nfcIndex
        self.value2 = value2
        type = .b1
        params = Data(bytes: [nfcIndex, value2])
    }
}

class B8Command : Command {
    var value : UInt8 = 0
    
    init(value: UInt8) {
        super.init()
        self.value = value
        type = .b8
        let content = Data(bytes: [UInt8](repeating: value, count: 24))
        var start = Data(bytes: [0x2b])
        start.append(content)
        params = start
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()): \(params.toHexString()))"
    }
}


class B9Command : Command {
    var value : UInt8 = 0

    init(value: UInt8) {
        super.init()
        self.value = value
        type = .b9
        params = Data(bytes: [value])
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()): \(params.toHexString()))"
    }
}

class BeCommand : Command {
    var value : UInt8 = 0
    
    init(value: UInt8) {
        super.init()
        self.value = value
        type = .be
        params = Data(bytes: [value])
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()): \(params.toHexString()))"
    }
}

class C0Command : Command {
    override init() {
        super.init()
        type = .c0
    }
}

class C1Command : Command {
    var value : UInt8 = 0
    
    init(value: UInt8) {
        super.init()
        self.value = value
        type = .c1
        params = Data(bytes: [value])
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()): \(params.toHexString()))"
    }
}

class C2Command : Command {
    var value : UInt8 = 0
    
    init(value: UInt8) {
        super.init()
        self.value = value
        type = .c2
        params = Data(bytes: [UInt8](repeating: value, count: 17))
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()): \(params.toHexString()))"
    }
}

class A4Command : Command {
    init(nfcIndex: UInt8, value: UInt8) {
        super.init()
        type = .a4
        var start = Data(bytes: [nfcIndex])
        let content = Data(bytes: [UInt8](repeating: value, count: 2))
        start.append(content)
        params = start
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()): \(params.toHexString()))"
    }
}

class ACommand : Command {
    init(nfcIndex: UInt8, value: UInt8) {
        super.init()
        var start = Data(bytes: [nfcIndex])
        let content = Data(bytes: [UInt8](repeating: value, count: 6))
        start.append(content)
        params = start
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()): \(params.toHexString()))"
    }
}

class A5Command : ACommand {
    override init(nfcIndex: UInt8, value: UInt8) {
        super.init(nfcIndex: nfcIndex, value: value)
        type = .a5
    }
}

class A6Command : ACommand {
    override init(nfcIndex: UInt8, value: UInt8) {
        super.init(nfcIndex: nfcIndex, value: value)
        type = .a6
    }
}

class A7Command : ACommand {
    override init(nfcIndex: UInt8, value: UInt8) {
        super.init(nfcIndex: nfcIndex, value: value)
        type = .a7
    }
}
