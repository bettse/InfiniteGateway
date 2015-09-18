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
    
    let dumpToken = true
    
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
    
    var key : NSData {
        get {
            //It is the first 16 bytes of a SHA1 hash of: a hard-coded 16 bytes, 15 bytes of the string "(c) Disney 2013", and the 7 bytes of the tag ID.
            //Each integer, or group of 4 bytes, of the SHA1 hash needs to be reversed because of endianness.

            let prekey = NSMutableData(capacity: AppDelegate.magic.length + AppDelegate.secret.length + tagId.length)!
            prekey.appendData(AppDelegate.secret)
            prekey.appendData(AppDelegate.magic)
            prekey.appendData(tagId)
            if (prekey.length != 16 + 15 + 7) {
                print("Pre-hashed key wasn't of the correct length")
                return NSData()
            }
            
            let sha = NSMutableData(length: Int(CC_SHA1_DIGEST_LENGTH))!
            let shaBytes = UnsafeMutablePointer<CUnsignedChar>(sha.mutableBytes)
            CC_SHA1(prekey.bytes, CC_LONG(prekey.length), shaBytes)            
            let truncatedSha = sha.subdataWithRange(NSMakeRange(0, 16))

            //Swap bytes for endianness
            let swappedKey = truncatedSha.bigEndianUInt32
            return NSData(data: swappedKey)
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
    var diskData : NSMutableData = NSMutableData()
    var encryptedData : NSMutableData = NSMutableData()
    
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
 
    func load(blockNumber: UInt8, blockData: NSData, debug: Bool = false) {
        encryptedData.appendData(blockData)        
        let clearData = decrypt(blockNumber, blockData: blockData)
        
        if (debug) {
            print("[\(blockNumber)]: \(clearData)")
        }
        
        switch blockNumber {
        case 0: //Manufacturer data
            let uidFromBlock = blockData.subdataWithRange(NSMakeRange(0, 7))
            if (!uidFromBlock.isEqualToData(tagId)) {
                print("Mismatch in tagid with tag data, \(tagId) vs block0 \(uidFromBlock)")
                //tagId = uidFromBlock
            }
            break
        case 1:
            clearData.getBytes(&modelId, range: NSMakeRange(modelIdIndex, sizeof(UInt32)))
            name = ThePoster.getName(modelId.bigEndian)
            //type = ThePoster.getType(modelId.bigEndian)
            clearData.getBytes(&generation, range: NSMakeRange(generationIndex, sizeof(UInt8)))
            //Y/M/D
            clearData.getBytes(&manufactureYear, range: NSMakeRange(manufactureYearIndex, sizeof(UInt8)))
            clearData.getBytes(&manufactureMonth, range: NSMakeRange(manufactureMonthIndex, sizeof(UInt8)))
            clearData.getBytes(&manufactureDay, range: NSMakeRange(manufactureDayIndex, sizeof(UInt8)))
            
            var diConstant : UInt16 = 0
            clearData.getBytes(&diConstant, range: NSMakeRange(disneyInfinityConstantIndex, sizeof(UInt16)))
            //if (diConstant.bigEndian != Token.DiConstant) { print("0xD11F constant mismatch: \(String(diConstant, radix: HEX))") }
        case 0x04:
            dataBlock = clearData
            parseDataBlock()
        case 0x05: //Skills
            clearData.getBytes(&skills, range: NSMakeRange(skillsIndex, sizeof(skills.dynamicType)))
            parseSkills()
        case 0x09: //Skills
            clearData.getBytes(&skills, range: NSMakeRange(skillsIndex, sizeof(skills.dynamicType)))
            parseSkills()
        case 0x08:
            var sequence4 : UInt8 = 0
            dataBlock.getBytes(&sequence4, range: NSMakeRange(sequenceIndex, sizeof(UInt8)))
            var sequence8 : UInt8 = 0
            clearData.getBytes(&sequence8, range: NSMakeRange(sequenceIndex, sizeof(UInt8)))
            if (sequence8 > sequence4) {
                dataBlock = clearData
            }
            parseDataBlock()

        case 0x0c:
            clearData.getBytes(&ownerId, range: NSMakeRange(ownerIdIndex, 3 /*UInt24*/))
            clearData.getBytes(&loadCount, range: NSMakeRange(loadCountIndex, sizeof(loadCount.dynamicType)))
        default:
            //Nothing interesting in this block?
            break
        }

        diskData.appendData(clearData)
        
        if (!verifyChecksum(clearData, blockNumber: blockNumber)) {
            print("Checksum failed for block \(blockNumber)")
        }

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
            print("Skills: \(String(skills, radix: BINARY))")
        }

    }

    func isEncrypted(blockNumber: UInt8, blockData: NSData) -> Bool {
        let zeros = NSData(bytes:[UInt8](count: blockData.length, repeatedValue: 0), length: blockData.length)
        
        if (blockNumber == 0 || blockNumber == 18 || sectorTrailer(blockNumber) || blockData.isEqualToData(zeros)) {
            return false
        }

        return true
    }

    //Each block is encrypted with a 128-bit AES key (ECB) unique to that figure.
    func decrypt(blockNumber: UInt8, blockData: NSData) -> NSData {
        if (UInt8(blockData.length) != Token.blockSize) {
            print("blockData must be exactly \(Token.blockSize) bytes")
            return blockData
        }

        if (!isEncrypted(blockNumber, blockData: blockData)) {
            return blockData
        }
        
        let operation : CCOperation = UInt32(kCCDecrypt)
        let algoritm : CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options : CCOptions   = UInt32(kCCOptionECBMode)
        
        let keyBytes = UnsafePointer<UInt8>(key.bytes)
        let keyLength : size_t = size_t(kCCKeySizeAES128)
        
        let dataBytes = UnsafePointer<UInt8>(blockData.bytes)
        let dataLength : size_t = size_t(blockData.length)

        let cryptData = NSMutableData(length: Int(blockData.length) + kCCBlockSizeAES128)!
        let cryptPointer = UnsafeMutablePointer<UInt8>(cryptData.mutableBytes)
        let cryptLength : size_t = size_t(cryptData.length)
        var numBytesEncrypted : size_t = 0
                
        let cryptStatus : CCCryptorStatus = CCCrypt(
            operation, algoritm, options,
            keyBytes, keyLength, nil,
            dataBytes, dataLength,
            cryptPointer, cryptLength, &numBytesEncrypted)
        
        if (UInt32(cryptStatus) != UInt32(kCCSuccess)) {
            print("Decryption failed")
        }
        
        return NSData(data: cryptData.subdataWithRange(NSMakeRange(0, blockData.length)))
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
    
    func sectorTrailer(blockNumber : UInt8) -> Bool {
        return (blockNumber + 1) % 4 == 0
    }
    
    func save(encrypted: Bool = false, withDatetime: Bool = false) {
        let downloads = NSSearchPathForDirectoriesInDomains(.DownloadsDirectory, .UserDomainMask, true)
        var filename = "\(tagId.hexadecimalString)-\(name)"
        if (withDatetime) {
            filename += "-\(dateFormat.stringFromDate(NSDate()))"
        }
        filename += ".bin"
        let fullPath = NSURL(fileURLWithPath: downloads[0]).URLByAppendingPathComponent(filename)
        
        if (encrypted) {
            encryptedData.writeToURL(fullPath, atomically: true)
        } else {
            diskData.writeToURL(fullPath, atomically: true)
        }
    }

    
}

