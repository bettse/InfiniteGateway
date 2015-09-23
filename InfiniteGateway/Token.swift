//
//  Token.swift
//  DIMP
//
//  Created by Eric Betts on 6/21/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

import CommonCrypto
import CommonCRC


//Tokens can be figures, disks (some are stackable), playsets (clear 3d figure with hex base)

class Token : MifareMini, CustomStringConvertible {

    static let DiConstant : UInt16 = 0xD11F // (i.e. D1sney 1nFinity)

    let DATE_OFFSET = 1356998400 //Jan 1, 2013
    let DATE_COEFFICIENT = 0x7b
    let BINARY = 2
    let HEX = 0x10
    
    //block 0x05/0x09
    let skillsIndex = 0x00
    let skillsSequenceIndex = 0x00
    
    let ownerIdIndex = 0x08 //block 0x0c
    let loadCountIndex = 0x0b //block 0x0c
    
    var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(tagId): v\(generation) \(name) L\(level)[\(experience)] | Manuf: \(manufactureYear)/\(manufactureMonth)/\(manufactureDay)"
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
            primaryDataBlock.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
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
    
    var primaryDataBlock : NSData {
        get {
            if (sequenceA > sequenceB) {
                return block(4)
            } else {
                return block(8)
            }
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
    
    var ownerId : UInt32 = 0
    var loadCount : UInt8 = 0
    var skills : UInt32 = 0
    
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

    
    func parseSkills() {
        //Choose the up skill for my first skill and it became
        //00 00 00 10 00 00 00 00 00 00 00 01
        //Choose the next further up skill and it became:
        //01 00 00 10 00 00 00 00 00 00 00 01 
        if (skills > 0) {
            //print("Skills: \(String(skills, radix: BINARY))")
        }

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
    
    func correctAllChecsums() {
        for blockNumber in 0..<MifareMini.blockCount {
            correctChecksum(blockNumber)
        }
    }
    
    func getChecksum(data: NSData) -> NSData {
        let dataBytes = UnsafePointer<UInt8>(data.bytes)
        let dataLength : size_t = size_t(data.length)
        
        var temp : UInt64 = 0
        let algoritm : CNcrc = UInt32(kCN_CRC_32_POSIX)
        let status : CNStatus = CNCRC(algoritm, dataBytes, dataLength, &temp)
        let checksumResult = NSData(bytes: &temp, length: sizeof(UInt32)).reverse.negation
        if (UInt32(status) == UInt32(kCNSuccess)) {
            return checksumResult
        }
        return NSData()
    }
    
    override func dump() {
        let downloads = NSSearchPathForDirectoriesInDomains(.DownloadsDirectory, .UserDomainMask, true)
        let filename = "\(tagId.hexadecimalString)-\(name).bin"
        let fullPath = NSURL(fileURLWithPath: downloads[0]).URLByAppendingPathComponent(filename)
        data.writeToURL(fullPath, atomically: true)
    }
    
    func save() {
        //send to PortalDriver to be re-encrypted before being sent back to token
    }    
    
}
