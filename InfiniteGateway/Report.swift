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
        case Unset = 0x00
        case Command = 0xFF
        case Response = 0xAA
        case Update = 0xAB
        func desc() -> String {
            return String(self).componentsSeparatedByString(".").last!
        }
    }
    
    var type : MessageType = .Unset
    var length = 0 //TODO: Convert to use getting/setter

    var content : Message? = nil // (command, response, update)

    var checksum : UInt8 {
        get {
            var sum = Int(type.rawValue)
            if let content = content as? Command {
                let b = UnsafeBufferPointer<UInt8>(start: UnsafePointer(content.serialize().bytes), count: length)
                
                for i in 0..<length {
                    sum += Int(b[i])
                }
            }
        
            return UInt8((sum + length) & 0xff)
        }
        set(newChecksum) {
            
        }
    }
    
    init(data: NSData) {
        //Extract type and checksum
        type = MessageType.init(rawValue: data[typeIndex])!
        length = Int(data[lengthIndex])
        checksum = data[lengthIndex + length]
        
        //Case statement for C R U
        switch type {
        case .Response:
            //Using parse to get back a Response subclass
            content = Response.parse(data.subdataWithRange(NSMakeRange(contentIndex, length)))
        case .Update:
            content = Update(data: data.subdataWithRange(NSMakeRange(contentIndex, length)))
        case .Command:
            content = Command(data: data.subdataWithRange(NSMakeRange(contentIndex, length)))
        default:
            print("Report type \(String(type.rawValue, radix:0x10)) len:\(length) checksum:\(checksum)")
        }
    }
    

    init(cmd: Command) {
        content = cmd
        type = .Command
        length = cmd.serialize().length
    }
    
    var description: String {
        let me = String(self.dynamicType).componentsSeparatedByString(".").last!
        return "\(me)::\(content!)"
    }
    
    func serialize() -> NSData {
        //Only applies to Command
        //Assumes checksum, length, type are already set
        if (content is Command) {
            let command = content as! Command
            let data = NSMutableData(length: 0x20)
            var rawType : UInt8 = type.rawValue
            if let data = data {
                data.replaceBytesInRange(NSMakeRange(typeIndex, sizeof(UInt8)), withBytes: &rawType)
                data.replaceBytesInRange(NSMakeRange(lengthIndex, sizeof(UInt8)), withBytes: &length)
                data.replaceBytesInRange(NSMakeRange(contentIndex, length), withBytes: command.serialize().bytes)
                data.replaceBytesInRange(NSMakeRange(contentIndex + length, sizeof(UInt8)), withBytes: &checksum)
                return data
            }
        }

        return NSData()
    }
}