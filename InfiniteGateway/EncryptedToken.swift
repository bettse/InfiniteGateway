//
//  EncryptedToken.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/18/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import CryptoSwift


class EncryptedToken : MifareMini {
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
            
            let sha = prekey.sha1()!.subdataWithRange(NSMakeRange(0, 16))
            //Swap bytes for endianness
            return sha.bigEndianUInt32
        }
    }
    
    var decryptedToken : Token {
        get {
            let clearToken : Token = Token(tagId: self.tagId)
            for blockNumber in 0..<MifareMini.blockCount {
                let encryptedBlock = block(blockNumber)
                let clearBlock = decrypt(blockNumber, blockData: encryptedBlock)
                clearToken.load(blockNumber, blockData: clearBlock)
            }
            return clearToken;
        }
    }
    
    convenience init(from: Token) {
        self.init(tagId: from.tagId)
        from.correctAllChecksums()
        for blockNumber in 0..<MifareMini.blockCount {
            let clearBlock = from.block(blockNumber)
            let encryptedBlock = encrypt(blockNumber, blockData: clearBlock)
            self.data.appendData(encryptedBlock)
        }
    }
    
    convenience init(image: NSData) {
        self.init(tagId: image.subdataWithRange(NSMakeRange(0, 7)))
        self.data = image.mutableCopy() as! NSMutableData
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
        if (blockData.length != MifareMini.blockSize) {
            print("blockData must be exactly \(MifareMini.blockSize) bytes")
            return blockData
        }
        
        if (skipEncryption(blockNumber, blockData: blockData)) {
            return blockData
        }
        
        let aes = try! AES(key: key.arrayOfBytes(), blockMode: .ECB)
        var newBytes : [UInt8]
        
        if (encrypt) {
            newBytes = try! aes.encrypt(blockData.arrayOfBytes(), padding: nil)
        } else {
            newBytes = try! aes.decrypt(blockData.arrayOfBytes(), padding: nil)
        }
        if (newBytes.count != MifareMini.blockSize) {
            print("Number of bytes after encryption/decryption was \(newBytes.count), but will be truncated")
        }
        return NSData(bytes: newBytes).subdataWithRange(NSMakeRange(0, MifareMini.blockSize))
    }
}





