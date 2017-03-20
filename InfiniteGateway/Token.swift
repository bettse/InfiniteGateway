//
//  Token.swift
//  DIMP
//
//  Created by Eric Betts on 6/21/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

//Tokens can be figures, disks (some are stackable), playsets (clear 3d figure with hex base)

class Token : MifareMini, CustomStringConvertible {
    static let DiConstant : UInt16 = 0xD11F // (i.e. D1sney 1nFinity)

    let DATE_OFFSET = 1356998400 //Jan 1, 2013
    let DATE_COEFFICIENT = 0x7b
    let BINARY = 2
    let HEX = 0x10
    
    lazy var portalDriver : PortalDriver  = {
        return PortalDriver.singleton
    }()
    
    var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)(\(tagId): v\(generation) \(name) L\(level)[\(experience)] | Manuf: \(manufactureYear)/\(manufactureMonth)/\(manufactureDay))"
    }
    
    override var filename : String {
        get {
            return "\(tagId.toHexString())-\(name).bin"
        }
    }

    var dateFormat : DateFormatter {
        get {
            let dateFormatter = DateFormatter()
            //dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
            //dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            dateFormatter.locale = Locale(identifier: "en_US")
            return dateFormatter
        }
    }

    var modelId : UInt32 {
        get {
            //TODO: Create a mapping of these characteristics to a property name
            let blockNumber = 1
            let blockIndex = 0
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            return data.subdata(in: offset..<data.count).uint32.bigEndian
        }
        set(value) {
            let blockNumber = 1
            let blockIndex = 0
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            data.replaceUInt32(offset, value: value)
        }
    }
    
    var name : String {
        get {
            return model.name
        }
    }

    //Can also be derived from modelNumber's 100's place value
    var generation : UInt8 {
        get {
            let blockNumber = 1
            let blockIndex = 0x09
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            return data[offset]
        }
        set(value) {
            let blockNumber = 1
            let blockIndex = 0x09
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            data.replaceUInt8(offset, value: value)
        }
    }
    
    var diConstant : UInt16 {
        get {
            let blockNumber = 1
            let blockIndex = 0x0A
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            let value = data.subdata(in: offset..<data.count).uint16
            if (value != Token.DiConstant) {
                log.warning("DiConstant was \(value) when it should be \(Token.DiConstant)")
            }
            return value
        }
        set (unused) {
            let blockNumber = 1
            let blockIndex = 0x0A
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            data.replaceUInt16(offset, value: Token.DiConstant.bigEndian)
        }
    }
    
    var correctDIConstant : Bool {
        get {
            return diConstant == Token.DiConstant
        }
    }
    
    var manufactureYear : UInt8 {
        get {
            let blockNumber = 1
            let blockIndex = 0x04
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            return data[offset]
        }
        set(value) {
            let blockNumber = 1
            let blockIndex = 0x04
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            data.replaceUInt8(offset, value: value)
        }
    }
    
    var manufactureMonth : UInt8 {
        get {
            let blockNumber = 1
            let blockIndex = 0x05
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            return data[offset]
        }
        set(value) {
            let blockNumber = 1
            let blockIndex = 0x05
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            data.replaceUInt8(offset, value: value)
        }
    }
    var manufactureDay : UInt8 {
        get {
            let blockNumber = 1
            let blockIndex = 0x06
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            return data[offset]
        }
        set(value) {
            let blockNumber = 1
            let blockIndex = 0x06
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            data.replaceUInt8(offset, value: value)
        }
    }
    
    var sequenceA : UInt8 {
        get {
            let blockNumber = 4
            let blockIndex = 0x0b
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            return data[offset]
        }
    }
    
    var sequenceB : UInt8 {
        get {
            let blockNumber = 8
            let blockIndex = 0x0b
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            return data[offset]
        }
    }
    
    var primaryDataBlockNumber : Int {
        get {
            return (sequenceA > sequenceB) ? 4 : 8
        }
    }
    
    var primaryDataBlock : Data {
        get {
            return block(primaryDataBlockNumber)
        }
    }
    
    var experience : UInt16 {
        get {
            let blockIndex = 0x03
            return primaryDataBlock.subdata(in: blockIndex..<primaryDataBlock.count).uint16
        }
        set(value) {
            let blockIndex = 0x03
            var blockNumber = 4
            if (sequenceB > sequenceA) {
                blockNumber += 4
            }
            var updatedBlock = block(blockNumber)
            updatedBlock.replaceUInt16(blockIndex, value: value)
            load(blockNumber, blockData: updatedBlock)
        }
    }
    
    var level : UInt8 {
        get {
            let blockIndex = 0x04
            return primaryDataBlock[blockIndex]
        }
    }

    var lastPlayed : UInt32 {
        get {
            //Multiply first 3 bytes by 0x7B, multiple top two MSB of 4th byte by 0x1E, sum.
            //This is the number of seconds since Jan 1, 2013 at the international date line.
            let blockIndex = 0x05
            return primaryDataBlock.subdata(in: blockIndex..<primaryDataBlock.count).uint32
        }
    }
    
    var ownerId : UInt16 {
        get {
            let blockNumber = 0x0C
            let blockIndex = 0x08
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            return data.subdata(in: offset..<data.count).uint16
        }
    }

    var loadCount : UInt8 {
        get {
            let blockNumber = 0x0C
            let blockIndex = 0x0B
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            return data[offset]
        }
    }

    var skillSequenceA : UInt8 {
        get {
            let blockNumber = 0x05
            let blockIndex = 0x0B
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            return data[offset]
        }
    }

    var skillSequenceB : UInt8 {
        get {
            let blockNumber = 0x09
            let blockIndex = 0x0B
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            return data[offset]
        }
    }

    
    var skillTree : UInt64 {
        get {
            //Choose the up skill for my first skill and it became
            //00 00 00 10 00 00 00 00 00 00 00 01
            //Choose the next further up skill and it became:
            //01 00 00 10 00 00 00 00 00 00 00 01

            if (skillSequenceA > skillSequenceB) {
                return block(5).uint64
            } else {
                return block(9).uint64
            }
        }
    }
    
    var model : Model {
        get {
            return Model(id: Int(modelId))
        }
    }

    var shortDisplay : String {
        get {
            switch model.shape {
            case Model.Shape.figure:
                return "\(model): Level \(level) [\(experience)]"
            default:
                return model.description
            }
        }
    }
    
    convenience init(modelId: Int) {
        //Make 7 bytes uid
        let value = UInt32(modelId).bigEndian
        var uid = Data(bytes: [0x04, 0x0e, 0x00, 0x00, 0x00, 0x00, 0x81])
        uid.replaceUInt32(2, value: value)

        self.init(tagId: uid)

        //Block 0
        var block0 = Data()
        block0.append(tagId)
        let block0remainder = (Int(MifareMini.blockSize) - uid.count)
        block0.append([UInt8](repeating: 0, count: block0remainder), count: block0remainder)
        self.load(0, blockData: block0)

        //Fill with zeros
        while !self.complete() {
            self.load(self.nextBlock(), blockData: MifareMini.emptyBlock)
        }
        
        //Setters for known values
        self.modelId = value
        self.manufactureYear = 14
        self.manufactureMonth = 7
        self.manufactureDay = 3
        self.diConstant = Token.DiConstant
        self.generation = Model(id: modelId).generation
        
        //Other misc
        data.replaceSubrange(MifareMini.blockSize+7..<MifareMini.blockSize+8, with: Data([0x02]))
        correctChecksum(1)
    }

    func verifyChecksum(_ blockData: Data, blockNumber: Int, update: Bool = false) -> Bool {
        //Excluded blocks
        if (blockNumber == 0 || blockNumber == 2 || sectorTrailer(blockNumber)) {
            return true
        }
        let checksumSize = 4 //UInt32
        let checksumIndex = Token.blockSize - checksumSize
        
        let withoutChecksum = Data(blockData.prefix(upTo: checksumIndex))
        let existingChecksum = Data(blockData.suffix(from: checksumIndex))
        
        let checksumResult = withoutChecksum.crc32(seed:0).negation        
        let valid = (existingChecksum == checksumResult)
        if (!valid) {
            if (update) {
                var blockDataWithChecksum : Data = Data()
                blockDataWithChecksum.append(blockData.subdata(in: 0..<checksumIndex))
                blockDataWithChecksum.append(checksumResult)
                load(blockNumber, blockData: blockDataWithChecksum)
            } else {
                log.warning("Calculated checksum \(checksumResult.toHexString()) but tag had \(existingChecksum.toHexString() )")
            }
        }
        return valid
    }
    
    func correctChecksum(_ blockNumber: Int) {
        let blockData = block(blockNumber)
        if (!verifyChecksum(blockData, blockNumber: blockNumber, update: true)) {
            log.info("Correcting bad checksum of block \(blockNumber)")
        }
    }
    
    func correctAllChecksums() {
        for blockNumber in 0..<MifareMini.blockCount {
            correctChecksum(blockNumber)
        }
    }
    
    func save() {
        //send to PortalDriver to be re-encrypted before being sent back to token
        let encryptedToken = EncryptedToken(from: self)
        let blockData = encryptedToken.block(primaryDataBlockNumber)
        let nfcIndex : UInt8 = 0//TODO: Fix this.
        portalDriver.portal.outputCommand(WriteCommand(nfcIndex: nfcIndex, sectorNumber: 0, blockNumber: primaryDataBlockNumber, blockData: blockData))
    }    
    
}
