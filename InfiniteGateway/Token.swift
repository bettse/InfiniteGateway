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

struct TokenStruct {
    
}

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
    
    //All blocks
    let checksumIndex = 0x0c //all blocks
    //Block 1
    let modelIdIndex = 0x00
    let NextBlockIndex = 0x07 //not sure yet
    let generationIndex = 0x09 // block 1  (DI 1.0 vs DI 2.0
    let disneyInfinityConstantIndex = 0x0A //block 1
    let manufactureYearIndex = 0x04
    let manufactureMonthIndex = 0x05
    let manufactureDayIndex = 0x06

    
    //block 0x04 or 0x08
    let sequenceIndex = 0x0b //only 0x04/0x08
    let experienceIndex = 0x03 //May end up being multibyte and starting at an earlier offset
    let levelIndex = 0x04
    let timestampIndex = 0x05
    
    //block 0x05/0x09
    let skillsIndex = 0x00
    let skillsSequenceIndex = 0x00
    
    let ownerIdIndex = 0x08 //block 0x0c
    let loadCountIndex = 0x0b //block 0x0c
    
    var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)(\(tagId): v\(generation) \(name) L\(level)[\(experience)] lastSaved \(lastSave) | Manuf: \(manufactureYear)/\(manufactureMonth)/\(manufactureDay)"
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
    
    var name : String = "<Unset>"
    var modelId : UInt32 = 0
    var dataBlock : NSData = NSData(bytes:[UInt8](count: Int(Token.blockSize), repeatedValue: 0), length: Int(Token.blockSize))
    var generation : UInt8 = 0
    var manufactureYear : UInt8 = 0
    var manufactureMonth : UInt8 = 0
    var manufactureDay : UInt8 = 0
    var experience : UInt16 = 0
    var level : UInt8 = 0
    var timestamp : UInt32 = 0
    var lastSave : NSDate = NSDate()
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
    
    func nextBlock() -> UInt8 {
        return UInt8(data.length / Int(Token.blockSize))
    }
    
    func complete() -> Bool{
        return (nextBlock() == Token.blockCount)
    }

    func load(blockNumber: UInt8, blockData: NSData) {
        data.appendData(blockData)
    }
    
    //May be called multiple times if block 0x8 has a higher sequence than 0x4
    func parseDataBlock() {
        dataBlock.getBytes(&level, range: NSMakeRange(levelIndex, sizeof(level.dynamicType)))
        dataBlock.getBytes(&experience, range: NSMakeRange(experienceIndex, sizeof(experience.dynamicType)))
        dataBlock.getBytes(&timestamp, range: NSMakeRange(timestampIndex, 3))
        timestamp = timestamp.bigEndian/0x100 //Correct for endianness
        lastSave = NSDate(timeIntervalSince1970: NSTimeInterval(Int(timestamp) * DATE_COEFFICIENT + DATE_OFFSET))
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
    
    func save() {
        let downloads = NSSearchPathForDirectoriesInDomains(.DownloadsDirectory, .UserDomainMask, true)
        let filename = "\(tagId.hexadecimalString)-\(name).bin"
        let fullPath = NSURL(fileURLWithPath: downloads[0]).URLByAppendingPathComponent(filename)
        
        data.writeToURL(fullPath, atomically: true)

    }

    
}

