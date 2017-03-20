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
        responseClass = A4Response.self
        type = .a4
    }
}

class A5Command : BlockCommand {
    init(nfcIndex: UInt8, sectorNumber: UInt8, blockNumber: UInt8, contents: Data) {
        super.init(nfcIndex: nfcIndex, sectorNumber: sectorNumber, blockNumber: blockNumber)
        responseClass = StatusResponse.self
        type = .a5
        params.append(contents)
    }
}

class A6Command : A5Command {

}

class A7Command : A5Command {
    
}

class B1Command : Command {
    var nfcIndex : UInt8 = 0
    var sectorNumber : UInt8 = 0
    
    init(nfcIndex: UInt8, sectorNumber: UInt8) {
        super.init(commandType: .b1)
        responseClass = StatusResponse.self
        self.nfcIndex = nfcIndex
        self.sectorNumber = sectorNumber
        params = Data(bytes: [nfcIndex, sectorNumber])
    }
}

class B8Command : Command {
    var value : UInt8 = 0
    
    init(value: UInt8) {
        super.init(commandType: .b8)
        responseClass = B8Response.self
        self.value = value
        let content = Data(bytes: [UInt8](repeating: value, count: 24))
        var start = Data(bytes: [0x2b])
        start.append(content)
        params = start
    }
}


class B9Command : Command {
    var value : UInt8 = 0
    
    init(value: UInt8) {
        super.init(commandType: .b9)
        responseClass = B9Response.self
        self.value = value
        params = Data(bytes: [value])
    }
}


//AppleTV Base only
class BeCommand : Command {
    var value : UInt8 = 0
    
    init(value: UInt8) {
        super.init(commandType: .be)
        responseClass = StatusResponse.self
        self.value = value
        params = Data(bytes: [value])
    }
}

class C0Command : Command {
    init() {
        super.init(commandType: .c0)
        responseClass = StatusResponse.self
    }
}

class C1Command : Command {
    var value : UInt8 = 0
    
    init(value: UInt8) {
        super.init(commandType: .c1)
        responseClass = StatusResponse.self
        self.value = value
        params = Data(bytes: [value])
    }
}

class C2Command : Command {
    var value : UInt8 = 0
    
    init(value: UInt8) {
        super.init(commandType: .c2)
        self.value = value
        params = Data(bytes: [UInt8](repeating: value, count: 17))
    }
}
