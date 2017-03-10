//
//  Report.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

//All data sent across USB is a 'Report'.  It always starts with a byte like 0xff/0xaa/0xab and ends with a summation checksum
//Sometimes the Reports are from device and need to be parsed, othertimes they're constructed and then need to be serialized



class Report {
    let typeIndex = 0
    let lengthIndex = 1
    let contentIndex = 2
    
    enum MessageType : UInt8 {
        case unset = 0x00
        case command = 0xFF
        case response = 0xAA
        case update = 0xAB
        func desc() -> String {
            return String(describing: self).components(separatedBy: ".").last!
        }
    }
    
    var type : MessageType = .unset
    var length = 0 //TODO: Convert to use getting/setter

    var content : Message? = nil // (command, response, update)

    var checksum : UInt8 {
        get {
            var sum = Int(type.rawValue)
            if let content = content as? Command {
                let b = UnsafeBufferPointer<UInt8>(start: (content.serialize() as NSData).bytes.bindMemory(to: UInt8.self, capacity: content.serialize().count), count: length)
                
                for i in 0..<length {
                    sum += Int(b[i])
                }
            }
        
            return UInt8((sum + length) & 0xff)
        }
        set(newChecksum) {
            
        }
    }
    
    init(data: Data) {
        //Extract type and checksum
        type = MessageType.init(rawValue: data[typeIndex])!
        length = Int(data[lengthIndex])
        checksum = data[lengthIndex + length]
        
        //Case statement for C R U
        switch type {
        case .response:
            //Using parse to get back a Response subclass
            content = Response.parse(data.subdata(in: contentIndex..<contentIndex+length))
        case .update:
            content = Update(data: data.subdata(in: contentIndex..<contentIndex+length))
        case .command:
            content = Command(data: data.subdata(in: contentIndex..<contentIndex+length))
        default:
            print("Report type \(String(type.rawValue, radix:0x10)) len:\(length) checksum:\(checksum)")
        }
    }
    

    init(cmd: Command) {
        content = cmd
        type = .command
        length = cmd.serialize().count
    }
    
    var description: String {
        let me = String(describing: type(of: self)).components(separatedBy: ".").last!
        return "\(me)::\(content!)"
    }
    
    func serialize() -> Data {
        //Only applies to Command
        //Assumes checksum, length, type are already set
        if (content is Command) {
            let command = content as! Command
            let data = NSMutableData(length: 0x20)
            var rawType : UInt8 = type.rawValue
            if let data = data {
                data.replaceBytes(in: NSMakeRange(typeIndex, MemoryLayout<UInt8>.size), withBytes: &rawType)
                data.replaceBytes(in: NSMakeRange(lengthIndex, MemoryLayout<UInt8>.size), withBytes: &length)
                data.replaceBytes(in: NSMakeRange(contentIndex, length), withBytes: (command.serialize() as NSData).bytes)
                data.replaceBytes(in: NSMakeRange(contentIndex + length, MemoryLayout<UInt8>.size), withBytes: &checksum)
                return data as Data
            }
        }

        return Data()
    }
}
