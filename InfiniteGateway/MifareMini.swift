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
    static let emptyBlock = Data(bytes: ([UInt8](repeating: 0, count: Int(MifareMini.blockSize))))
    
    let sector_trailor = Data(bytes: [0, 0, 0, 0, 0, 0, 0x77, 0x87, 0x88, 0, 0, 0, 0, 0, 0, 0])
    
    var tagId : Data
    var data : Data = Data()
    
    var uid : Data {
        get {
            return tagId
        }
    }
    
    var filename : String {
        get {
            return "\(tagId.toHexString()).bin"
        }
    }
    
    init(tagId: Data) {
        self.tagId = tagId
    }
    
    func nextBlock() -> Int {
        return data.count / MifareMini.blockSize
    }
    
    func complete() -> Bool{
        return (nextBlock() == MifareMini.blockCount)
    }
    
    func block(_ blockNumber: UInt8) -> Data {
        return block(Int(blockNumber))
    }
    
    func block(_ blockNumber: Int) -> Data {
        let blockStart = blockNumber * MifareMini.blockSize
        return data.subdata(in: blockStart..<blockStart+MifareMini.blockSize)
    }
    
    func load(_ blockNumber: Int, blockData: Data) {
        if (blockNumber == nextBlock()) {
            data.append(blockData)
        } else {
            let start = blockNumber * MifareMini.blockSize
            let end = start + MifareMini.blockSize
            let blockRange = start..<end
            data.replaceSubrange(blockRange, with: blockData)
        }
        
    }
    
    func load(_ blockNumber: UInt8, blockData: Data) {
        load(Int(blockNumber), blockData: blockData)
    }
    
    func sectorTrailer(_ blockNumber : Int) -> Bool {
        return (blockNumber + 1) % 4 == 0
    }
    
    func dump(_ path: URL) {
        let fullPath = path.appendingPathComponent(filename)
        try! data.write(to: fullPath)
    }
}
