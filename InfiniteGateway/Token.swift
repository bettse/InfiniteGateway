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
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(tagId): v\(generation) \(name) L\(level)[\(experience)] | Manuf: \(manufactureYear)/\(manufactureMonth)/\(manufactureDay)"
    }
    
    override var filename : String {
        get {
            return "\(tagId.hexadecimalString)-\(name).bin"
        }
    }


    var dateFormat : NSDateFormatter {
        get {
            let dateFormatter = NSDateFormatter()
            //dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
            //dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US")
            return dateFormatter
        }
    }

    var modelId : UInt32 {
        get {
            //TODO: Create a mapping of these characteristics to a property name
            let blockNumber = 1
            let blockIndex = 0
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt32 = 0
            let size = sizeof(value.dynamicType)
            data.getBytes(&value, range: NSMakeRange(offset, size))
            return value.bigEndian
        }
        set(newModelId) {
            let blockNumber = 1
            let blockIndex = 0
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt32 = newModelId.littleEndian
            let size = sizeof(value.dynamicType)
            data.replaceBytesInRange(NSMakeRange(offset, size), withBytes: &value)
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
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
        set(newGeneration) {
            let blockNumber = 1
            let blockIndex = 0x09
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt8 = newGeneration
            let size = sizeof(value.dynamicType)
            data.replaceBytesInRange(NSMakeRange(offset, size), withBytes: &value)
        }
    }
    
    var diConstant : UInt16 {
        get {
            let blockNumber = 1
            let blockIndex = 0x0A
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt16 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            if (value != Token.DiConstant) {
                print("DiConstant was \(value) when it should be \(Token.DiConstant)")
            }
            return value
        }
        set (unused) {
            let blockNumber = 1
            let blockIndex = 0x0A
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt16 = Token.DiConstant.bigEndian
            let size = sizeof(value.dynamicType)
            data.replaceBytesInRange(NSMakeRange(offset, size), withBytes: &value)
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
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
        set(newYear) {
            let blockNumber = 1
            let blockIndex = 0x04
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt8 = newYear
            let size = sizeof(value.dynamicType)
            data.replaceBytesInRange(NSMakeRange(offset, size), withBytes: &value)
        }
    }
    
    var manufactureMonth : UInt8 {
        get {
            let blockNumber = 1
            let blockIndex = 0x05
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
        set(newMonth) {
            let blockNumber = 1
            let blockIndex = 0x05
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt8 = newMonth
            let size = sizeof(value.dynamicType)
            data.replaceBytesInRange(NSMakeRange(offset, size), withBytes: &value)
        }
    }
    var manufactureDay : UInt8 {
        get {
            let blockNumber = 1
            let blockIndex = 0x06
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
        set(newDay) {
            let blockNumber = 1
            let blockIndex = 0x06
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt8 = newDay
            let size = sizeof(value.dynamicType)
            data.replaceBytesInRange(NSMakeRange(offset, size), withBytes: &value)
        }
    }
    
    var sequenceA : UInt8 {
        get {
            let blockNumber = 4
            let blockIndex = 0x0b
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
    }
    
    var sequenceB : UInt8 {
        get {
            let blockNumber = 8
            let blockIndex = 0x0b
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
    }
    
    var primaryDataBlockNumber : Int {
        get {
            return (sequenceA > sequenceB) ? 4 : 8
        }
    }
    
    var primaryDataBlock : NSData {
        get {
            return block(primaryDataBlockNumber)
        }
    }
    
    var experience : UInt16 {
        get {
            let blockIndex = 0x03
            var value : UInt16 = 0
            primaryDataBlock.getBytes(&value, range: NSMakeRange(blockIndex, sizeof(value.dynamicType)))
            return value
        }
        set(newExperience) {
            let blockIndex = 0x03
            var value : UInt16 = newExperience
            var blockNumber = 4
            if (sequenceB > sequenceA) {
                blockNumber += 4
            }
            let updatedBlock : NSMutableData = block(blockNumber).mutableCopy() as! NSMutableData
            updatedBlock.replaceBytesInRange(NSMakeRange(blockIndex, sizeof(value.dynamicType)), withBytes: &value)
            load(blockNumber, blockData: updatedBlock)
        }
    }
    
    var level : UInt8 {
        get {
            let blockIndex = 0x04
            var value : UInt8 = 0
            primaryDataBlock.getBytes(&value, range: NSMakeRange(blockIndex, sizeof(value.dynamicType)))
            return value
        }
    }

    var lastPlayed : UInt32 {
        get {
            //Multiply first 3 bytes by 0x7B, multiple top two MSB of 4th byte by 0x1E, sum.
            //This is the number of seconds since Jan 1, 2013 at the international date line.
            let blockIndex = 0x05
            var value : UInt32 = 0
            primaryDataBlock.getBytes(&value, range: NSMakeRange(blockIndex, sizeof(value.dynamicType)))
            return value
        }
    }
    
    var ownerId : UInt16 {
        get {
            let blockNumber = 0x0C
            let blockIndex = 0x08
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt16 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
    }

    var loadCount : UInt8 {
        get {
            let blockNumber = 0x0C
            let blockIndex = 0x0B
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
    }

    var skillSequenceA : UInt8 {
        get {
            let blockNumber = 0x05
            let blockIndex = 0x0B
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
    }

    var skillSequenceB : UInt8 {
        get {
            let blockNumber = 0x09
            let blockIndex = 0x0B
            let offset = blockNumber * MifareMini.blockSize + blockIndex
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
    }

    
    var skillTree : UInt64 {
        get {
            var primarySkillBlock : NSData
            if (skillSequenceA > skillSequenceB) {
                primarySkillBlock = block(5)
            } else {
                primarySkillBlock = block(9)
            }

            //Choose the up skill for my first skill and it became
            //00 00 00 10 00 00 00 00 00 00 00 01
            //Choose the next further up skill and it became:
            //01 00 00 10 00 00 00 00 00 00 00 01
            
            print(primarySkillBlock)
            var value : UInt64 = 0
            primarySkillBlock.getBytes(&value, range: NSMakeRange(0, sizeof(value.dynamicType)))
            return value
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
            case Model.Shape.Figure:
                return "\(model): Level \(level) [\(experience)]"
            default:
                return model.description
            }
        }
    }
    
    convenience init(modelId: Int) {
        //Make 7 bytes uid
        var value = UInt32(modelId).bigEndian
        let uid = NSMutableData(bytes:[0x04, 0x0e, 0x00, 0x00, 0x00, 0x00, 0x81] as [UInt8], length: 7)
        uid.replaceBytesInRange(NSMakeRange(2, sizeof(value.dynamicType)), withBytes: &value)
        self.init(tagId: uid)

        //Block 0
        let block0 = NSMutableData()
        block0.appendData(tagId)
        let block0remainder = (Int(MifareMini.blockSize) - uid.length)
        block0.appendBytes([UInt8](count: block0remainder, repeatedValue: 0), length: block0remainder)
        self.load(0, blockData: block0)

        //Fill with zeros
        while !self.complete() {
            self.load(self.nextBlock(), blockData: emptyBlock)
        }
        
        //Setters for known values
        self.modelId = value
        self.manufactureYear = 14
        self.manufactureMonth = 7
        self.manufactureDay = 3
        self.diConstant = Token.DiConstant
        self.generation = UInt8(modelId / 100 % 10) + 1
        
        //Other misc
        var bytes : [UInt8] = [0x02]
        let miscRange = NSMakeRange(MifareMini.blockSize + 7, 1)
        data.replaceBytesInRange(miscRange, withBytes: &bytes)
        correctChecksum(1)
    }

    func verifyChecksum(blockData: NSData, blockNumber: Int, update: Bool = false) -> Bool {
        //Excluded blocks
        if (blockNumber == 0 || blockNumber == 2 || sectorTrailer(blockNumber)) {
            return true
        }
        let checksumIndex = Token.blockSize - sizeof(UInt32) //12
        
        let existingChecksum = blockData.subdataWithRange(NSMakeRange(checksumIndex, sizeof(UInt32)))
        let data = blockData.subdataWithRange(NSMakeRange(0, checksumIndex)).reverse
        let checksumResult = getChecksum(data)
        
        let valid = (existingChecksum.isEqualToData(checksumResult))
        if (!valid) {
            if (update) {
                let blockDataWithChecksum : NSMutableData = NSMutableData()
                blockDataWithChecksum.appendData(blockData.subdataWithRange(NSMakeRange(0, checksumIndex)))
                blockDataWithChecksum.appendData(checksumResult)
                load(blockNumber, blockData: blockDataWithChecksum)
            } else {
                print("Expected checksum \(checksumResult) but tag had \(existingChecksum)")
            }
        }
        return valid
    }
    
    func correctChecksum(blockNumber: Int) {
        let blockData = block(blockNumber)
        verifyChecksum(blockData, blockNumber: blockNumber, update: true)
    }
    
    func correctAllChecksums() {
        for blockNumber in 0..<MifareMini.blockCount {
            correctChecksum(blockNumber)
        }
    }
    
    func getChecksum(data: NSData) -> NSData {
        let crc32 = data.crc32()
        let checksumResult = crc32!.reverse.negation
        return checksumResult
    }
    
    func save() {
        //send to PortalDriver to be re-encrypted before being sent back to token
        let encryptedToken = EncryptedToken(from: self)
        let blockData = encryptedToken.block(primaryDataBlockNumber)
        let nfcIndex : UInt8 = 0//TODO: Fix this.
        portalDriver.portal.outputCommand(WriteCommand(nfcIndex: nfcIndex, block: primaryDataBlockNumber, blockData: blockData))
    }    
    
}
