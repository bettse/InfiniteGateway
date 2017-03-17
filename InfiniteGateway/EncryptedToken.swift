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
    var key : Data {
        get {
            //It is the first 16 bytes of a SHA1 hash of: a hard-coded 16 bytes, 15 bytes of the string "(c) Disney 2013", and the 7 bytes of the tag ID.
            //Each integer, or group of 4 bytes, of the SHA1 hash needs to be reversed because of endianness.
            
            var prekey = Data() //PortalDriver.magic.length + PortalDriver.secret.length + tagId.length
            prekey.append(PortalDriver.secret)
            prekey.append(PortalDriver.magic)
            prekey.append(tagId)
            if (prekey.count != 38) {
                print("Pre-hashed key wasn't of the correct length")
                return Data()
            }
            
            let sha = prekey.sha1().subdata(in: 0..<16)
            //Swap bytes for endianness
            return sha.bigEndianUInt32
        }
    }
    
    var decryptedToken : Token? {
        get {
            let clearToken : Token = Token(tagId: self.tagId)
            for blockNumber in 0..<MifareMini.blockCount {
                let encryptedBlock = block(blockNumber)
                let clearBlock = decrypt(blockNumber, blockData: encryptedBlock)
                if(clearToken.verifyChecksum(clearBlock, blockNumber: blockNumber)) {
                    clearToken.load(blockNumber, blockData: clearBlock)
                } else {
                    print("Could not load block \(blockNumber) due to failed checksum")
                    return nil
                }
            }
            return clearToken;
        }
    }
    
    var name : String {
        get {
            return decryptedToken?.model.name ?? "Invalid"
        }
    }
    
    override var filename : String {
        get {
            return "\(tagId.toHexString())-\(name).bin"
        }
    }
    
    convenience init(from: Token) {
        self.init(tagId: from.tagId)
        from.correctAllChecksums()
        for blockNumber in 0..<MifareMini.blockCount {
            let clearBlock = from.block(blockNumber)
            let encryptedBlock = encrypt(blockNumber, blockData: clearBlock)
            self.data.append(encryptedBlock)
        }
    }
    
    convenience init(image: Data) {
        self.init(tagId: image.subdata(in: 0..<7))
        self.data = image
    }

    func skipEncryption(_ blockNumber: Int, blockData: Data) -> Bool {
        return (blockNumber == 0 || blockNumber == 18 || sectorTrailer(blockNumber) || (blockData == emptyBlock))
    }
    
    //Each block is encrypted with a 128-bit AES key (ECB) unique to that figure.
    func decrypt(_ blockNumber: Int, blockData: Data) -> Data {
        return commonCrypt(blockNumber, blockData: blockData, encrypt: false)
    }

    //Each block is encrypted with a 128-bit AES key (ECB) unique to that figure.
    func encrypt(_ blockNumber: Int, blockData: Data) -> Data {
        return commonCrypt(blockNumber, blockData: blockData, encrypt: true)
    }
    
    func commonCrypt(_ blockNumber: Int, blockData: Data, encrypt: Bool) -> Data {
        if (blockData.count != MifareMini.blockSize) {
            print("blockData must be exactly \(MifareMini.blockSize) bytes")
            return blockData
        }
        
        if (skipEncryption(blockNumber, blockData: blockData)) {
            return blockData
        }
        
        let aes = try! AES(key: [UInt8](key), iv: nil, blockMode: .ECB, padding: NoPadding())    
        var newBytes : [UInt8]
        
        if (encrypt) {
            newBytes = try! aes.encrypt([UInt8](blockData))
        } else {
            newBytes = try! aes.decrypt([UInt8](blockData))
        }
        if (newBytes.count != MifareMini.blockSize) {
            print("Number of bytes after encryption/decryption was \(newBytes.count), but will be truncated")
        }
        return Data(newBytes).subdata(in: 0..<MifareMini.blockSize)
    }
}





