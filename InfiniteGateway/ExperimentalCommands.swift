//
//  ExperimentalCommands.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 3/17/17.
//  Copyright © 2017 Eric Betts. All rights reserved.
//

import Foundation


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
