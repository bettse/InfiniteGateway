//
//  EncryptedToken.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/18/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

import CommonCrypto
import CommonCRC


class EncryptedToken : Token {
    var key : NSData {
        get {
            //It is the first 16 bytes of a SHA1 hash of: a hard-coded 16 bytes, 15 bytes of the string "(c) Disney 2013", and the 7 bytes of the tag ID.
            //Each integer, or group of 4 bytes, of the SHA1 hash needs to be reversed because of endianness.
            
            let prekey = NSMutableData(capacity: 38)! //PortalDriver.magic.length + PortalDriver.secret.length + tagId.length
            prekey.appendData(PortalDriver.secret)
            prekey.appendData(PortalDriver.magic)
            prekey.appendData(tagId)
            if (prekey.length != 38) {
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
    
    convenience init(from: Token) {
        self.init(tagId: from.tagId)
        for blockNumber in 0..<Token.blockCount {
            let clearBlock = from.block(blockNumber)
            let encryptedBlock = encrypt(blockNumber, blockData: clearBlock)
            self.data.appendData(encryptedBlock)
        }
    }
    
    func getDecryptedToken() -> Token {
        let clearToken : Token = Token(tagId: self.tagId)
        for blockNumber in 0..<Token.blockCount {
            let encryptedBlock = block(blockNumber)
            let clearBlock = decrypt(blockNumber, blockData: encryptedBlock)
            clearToken.load(blockNumber, blockData: clearBlock)
        }
        
        return clearToken;
    }
    
    func skipEncryption(blockNumber: Int, blockData: NSData) -> Bool {
        return (blockNumber == 0 || blockNumber == 18 || sectorTrailer(blockNumber) || blockData.isEqualToData(emptyBlock))
    }
    
    //Each block is encrypted with a 128-bit AES key (ECB) unique to that figure.
    func decrypt(blockNumber: Int, blockData: NSData) -> NSData {
        return commonCrypt(blockNumber, blockData: blockData, encrypt: false)
    }

    //Each block is encrypted with a 128-bit AES key (ECB) unique to that figure.
    func encrypt(blockNumber: Int, blockData: NSData) -> NSData {
        return commonCrypt(blockNumber, blockData: blockData, encrypt: true)
    }

    func commonCrypt(blockNumber: Int, blockData: NSData, encrypt: Bool) -> NSData {
        if (blockData.length != Token.blockSize) {
            print("blockData must be exactly \(Token.blockSize) bytes")
            return blockData
        }
        
        if (skipEncryption(blockNumber, blockData: blockData)) {
            return blockData
        }
        
        var operation : CCOperation
        if (encrypt) {
            operation = UInt32(kCCEncrypt)
        } else {
            operation = UInt32(kCCDecrypt)
        }
        

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
            print("Encryption failed")
        }
        
        return cryptData.subdataWithRange(NSMakeRange(0, blockData.length))
    }
    
    override func dump() {
        let downloads = NSSearchPathForDirectoriesInDomains(.DownloadsDirectory, .UserDomainMask, true)
        let filename = "\(tagId.hexadecimalString)-Encrypted.bin"
        let fullPath = NSURL(fileURLWithPath: downloads[0]).URLByAppendingPathComponent(filename)
        data.writeToURL(fullPath, atomically: true)
    }
}





