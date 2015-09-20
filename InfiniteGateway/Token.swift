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

class Token : CustomStringConvertible {
    static let sectorSize : UInt8 = 4 //Blocks
    static let sectorCount : UInt8 = 5
    static let blockCount : UInt8 = sectorSize * sectorCount
    static let blockSize : UInt8 = 0x10
    static let tokenSize : UInt8 = blockSize * blockCount
    static let DiConstant : UInt16 = 0xD11F // (i.e. D1sney 1nFinity)
    static let importantBlockNumbers : [UInt8:UInt8] = [0: 1, 1: 4, 4:8, 8:12]

    let DATE_OFFSET = 1356998400 //Jan 1, 2013
    let DATE_COEFFICIENT = 0x7b
    let BINARY = 2
    let HEX = 0x10
    let sector_trailor = NSData(bytes: [0, 0, 0, 0, 0, 0, 0x77, 0x87, 0x88, 0, 0, 0, 0, 0, 0, 0,], length: 16)
    let emptyBlock = NSData(bytes:[UInt8](count: Int(Token.blockSize), repeatedValue: 0), length: Int(Token.blockSize))
    
    //All blocks
    let checksumIndex = 0x0c //all blocks
    
    //block 0x05/0x09
    let skillsIndex = 0x00
    let skillsSequenceIndex = 0x00
    
    let ownerIdIndex = 0x08 //block 0x0c
    let loadCountIndex = 0x0b //block 0x0c
    
    var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(tagId): v\(generation) \(name) L\(level)[\(experience)] | Manuf: \(manufactureYear)/\(manufactureMonth)/\(manufactureDay)"
    }
    var tagId : NSData
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
            let blockNumber : UInt8 = 1
            let blockIndex : UInt8 = 0
            let offset = Int(blockNumber * Token.blockSize + blockIndex)
            var value : UInt32 = 0
            let size = sizeof(value.dynamicType)
            data.getBytes(&value, range: NSMakeRange(offset, size))
            return value
        }
        set(newModelId) {
            let blockNumber : UInt8 = 1
            let blockIndex : UInt8 = 0
            let offset = Int(blockNumber * Token.blockSize + blockIndex)
            var value : UInt32 = newModelId
            let size = sizeof(value.dynamicType)
            data.replaceBytesInRange(NSMakeRange(offset, size), withBytes: &value)
        }
    }
    
    var name : String {
        get {
            return ThePoster.getName(modelId.bigEndian)
        }
    }

    //Can also be derived from modelNumber's 100's place value
    var generation : UInt8 {
        get {
            let blockNumber : UInt8 = 1
            let blockIndex : UInt8 = 0x09
            let offset = Int(blockNumber * Token.blockSize + blockIndex)
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
        set(newGeneration) {
            let blockNumber : UInt8 = 1
            let blockIndex : UInt8 = 0x09
            let offset = Int(blockNumber * Token.blockSize + blockIndex)
            var value : UInt8 = newGeneration
            let size = sizeof(value.dynamicType)
            data.replaceBytesInRange(NSMakeRange(offset, size), withBytes: &value)
        }
    }
    
    var diConstant : UInt16 {
        get {
            let blockNumber : UInt8 = 1
            let blockIndex : UInt8 = 0x0A
            let offset = Int(blockNumber * Token.blockSize + blockIndex)
            var value : UInt16 = 0
            primaryDataBlock.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            if (value != Token.DiConstant) {
                print("DiConstant was \(value) when it should be \(Token.DiConstant)")
            }
            return value
        }
        set (unused) {
            let blockNumber : UInt8 = 1
            let blockIndex : UInt8 = 0x0A
            let offset = Int(blockNumber * Token.blockSize + blockIndex)
            var value : UInt16 = Token.DiConstant
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
            let blockNumber : UInt8 = 1
            let blockIndex : UInt8 = 0x04
            let offset = Int(blockNumber * Token.blockSize + blockIndex)
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
    }
    
    var manufactureMonth : UInt8 {
        get {
            let blockNumber : UInt8 = 1
            let blockIndex : UInt8 = 0x05
            let offset = Int(blockNumber * Token.blockSize + blockIndex)
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
    }
    var manufactureDay : UInt8 {
        get {
            let blockNumber : UInt8 = 1
            let blockIndex : UInt8 = 0x06
            let offset = Int(blockNumber * Token.blockSize + blockIndex)
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
    }
    
    var sequenceA : UInt8 {
        get {
            let blockNumber : UInt8 = 4
            let blockIndex : UInt8 = 0x0b
            let offset = Int(blockNumber * Token.blockSize + blockIndex)
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
    }
    
    var sequenceB : UInt8 {
        get {
            let blockNumber : UInt8 = 8
            let blockIndex : UInt8 = 0x0b
            let offset = Int(blockNumber * Token.blockSize + blockIndex)
            var value : UInt8 = 0
            data.getBytes(&value, range: NSMakeRange(offset, sizeof(value.dynamicType)))
            return value
        }
    }
    
    var primaryDataBlock : NSData {
        get {
            var range : NSRange
            if (sequenceA > sequenceB) {
                range = NSMakeRange(Int(Token.blockSize) * 4, Int(Token.blockSize))
            } else {
                range = NSMakeRange(Int(Token.blockSize) * 8, Int(Token.blockSize))
            }
            return data.subdataWithRange(range)
        }
    }
    
    var experience : UInt16 {
        get {
            let blockIndex = 0x03
            var value : UInt16 = 0
            primaryDataBlock.getBytes(&value, range: NSMakeRange(blockIndex, sizeof(value.dynamicType)))
            return value
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
    var data : NSMutableData = NSMutableData()
    
    var type : String {
        get {
            switch modelId {
            case 1000000..<2000000:
                return "Figure"
            case 2000000..<3000000:
                return "Play Sets / Toy Box"
            case 3000000..<4000000:
                return "Round Power Disc"
            case 4000000..<5000000:
                return "Hexagonal Power Disc"
            default:
                return "Unknown"
            }
        }
    }

    init(tagId: NSData) {
        self.tagId = tagId
    }
    
    init(modelId: UInt32) {
        //Make 7 bytes uid
        let uid = NSMutableData(bytes: [0, 0, 0, 0, 0, 0, 0] as [UInt8], length: 7)
        var value = modelId
        uid.replaceBytesInRange(NSMakeRange(0, sizeof(modelId.dynamicType)), withBytes: &value)
        self.tagId = uid
        
        //Load empty data
        for blockNumber in 0..<Token.blockCount {
            self.load(blockNumber, blockData: emptyBlock)
        }
        //Run minimal setters
        self.modelId = modelId
        self.diConstant = Token.DiConstant
        self.generation = UInt8(modelId / 100 % 10)
    }
    
    func nextBlock() -> UInt8 {
        return UInt8(data.length / Int(Token.blockSize))
    }
    
    func complete() -> Bool{
        return (nextBlock() == Token.blockCount)
    }

    func load(blockNumber: UInt8, blockData: NSData) {
        data.appendData(blockData)
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
    
    func sectorTrailer(blockNumber : UInt8) -> Bool {
        return (blockNumber + 1) % 4 == 0
    }
    
    func verifyChecksum(blockData: NSData, blockNumber: UInt8) -> Bool {
        //Excluded blocks
        if (blockNumber == 0 || blockNumber == 2 || sectorTrailer(blockNumber)) {
            return true
        }
        
        let existingChecksum = blockData.subdataWithRange(NSMakeRange(checksumIndex, sizeof(UInt32)))
        let data = blockData.subdataWithRange(NSMakeRange(0, checksumIndex)).reverse
        let checksumResult = getChecksum(data)
        
        let valid = (existingChecksum.isEqualToData(checksumResult))
        if (!valid) {
            print("Expected checksum \(checksumResult) but tag had \(existingChecksum)")
        }
        return valid
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
    
    func dump() {
        let downloads = NSSearchPathForDirectoriesInDomains(.DownloadsDirectory, .UserDomainMask, true)
        let filename = "\(tagId.hexadecimalString)-\(name).bin"
        let fullPath = NSURL(fileURLWithPath: downloads[0]).URLByAppendingPathComponent(filename)
        data.writeToURL(fullPath, atomically: true)
    }
    
    func save() {
        //send to PortalDriver to be re-encrypted before being sent back to token
    }

    
    
}
