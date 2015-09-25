//
//  MifareMini.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/20/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

class MifareMini {
    static let sectorSize : Int = 4 //Blocks
    static let sectorCount : Int = 5
    static let blockCount : Int = sectorSize * sectorCount
    static let blockSize : Int = 0x10
    static let tokenSize : Int = blockSize * blockCount
    
    let sector_trailor = NSData(bytes: [0, 0, 0, 0, 0, 0, 0x77, 0x87, 0x88, 0, 0, 0, 0, 0, 0, 0,], length: 16)    
    let emptyBlock = NSData(bytes:[UInt8](count: Int(MifareMini.blockSize), repeatedValue: 0), length: Int(MifareMini.blockSize))
    
    var tagId : NSData
    var data : NSMutableData = NSMutableData()
    
    var uid : NSData {
        get {
            return tagId
        }
    }
    
    var filename : String {
        get {
            return "\(tagId.hexadecimalString).bin"
        }
    }
    
    init(tagId: NSData) {
        self.tagId = tagId
    }
    
    func nextBlock() -> Int {
        return data.length / MifareMini.blockSize
    }
    
    func complete() -> Bool{
        return (nextBlock() == MifareMini.blockCount)
    }
    
    func block(blockNumber: UInt8) -> NSData {
        return block(Int(blockNumber))
    }
    
    func block(blockNumber: Int) -> NSData {
        let blockStart = blockNumber * MifareMini.blockSize
        let blockRange = NSMakeRange(blockStart, MifareMini.blockSize)
        return data.subdataWithRange(blockRange)
    }
    
    func load(blockNumber: Int, blockData: NSData) {
        if (blockNumber == nextBlock()) {
            data.appendData(blockData)
        } else {
            let blockRange = NSMakeRange(blockNumber * MifareMini.blockSize, MifareMini.blockSize)
            data.replaceBytesInRange(blockRange, withBytes: blockData.bytes)
        }
        
    }
    
    func load(blockNumber: UInt8, blockData: NSData) {
        load(Int(blockNumber), blockData: blockData)
    }
    
    func sectorTrailer(blockNumber : Int) -> Bool {
        return (blockNumber + 1) % 4 == 0
    }
    
    func dump(path: NSURL) {
        let fullPath = path.URLByAppendingPathComponent(filename)
        data.writeToURL(fullPath, atomically: true)
    }
}