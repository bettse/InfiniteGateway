//
//  ExperimentalCommands.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 3/17/17.
//  Copyright © 2017 Eric Betts. All rights reserved.
//

import Foundation


class A4Command : BlockCommand {
    
    override init(nfcIndex: UInt8, sectorNumber: UInt8, blockNumber: UInt8) {
        super.init(nfcIndex: nfcIndex, sectorNumber: sectorNumber, blockNumber: blockNumber)
        type = .a4
    }
}

class B1Command : Command {
    var nfcIndex : UInt8 = 0
    var sectorNumber : UInt8 = 0
    
    init(nfcIndex: UInt8, sectorNumber: UInt8) {
        super.init(commandType: .b1)
        self.nfcIndex = nfcIndex
        self.sectorNumber = sectorNumber
        params = Data(bytes: [nfcIndex, sectorNumber])
    }
}

class B8Command : Command {
    var value : UInt8 = 0
    
    init(value: UInt8) {
        super.init(commandType: .b8)
        self.value = value
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
        super.init(commandType: .b9)
        self.value = value
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
        super.init(commandType: .be)
        self.value = value
        params = Data(bytes: [value])
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()): \(params.toHexString()))"
    }
}

class C0Command : Command {
    init() {
        super.init(commandType: .c0)
    }
}

class C1Command : Command {
    var value : UInt8 = 0
    
    init(value: UInt8) {
        super.init(commandType: .c1)
        self.value = value
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
        super.init(commandType: .c2)
        self.value = value
        params = Data(bytes: [UInt8](repeating: value, count: 17))
    }
    
    override var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(type.desc()): \(params.toHexString()))"
    }
}
