//
//  Portal.swift
//  DIMP
//
//  Created by Eric Betts on 6/17/15.
//  Copyright (c) 2015 Eric Betts. All rights reserved.
//

import Foundation
import IOKit.hid

//Portal inherits from NSObject so we can use it with NSThread
class Portal : NSObject {
    let vendorId = 0x0e6f
    let productId = 0x0129
    let reportSize : CFIndex = 0x20
    static let singleton = Portal()
    var device : IOHIDDevice? = nil
    
    func input(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {
        let raw = Data(bytes: report, count: reportLength)
        log.verbose("<= \(raw.toHexString())")
        let report = Report(data: raw)
        if let msg = report.content {
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "incomingMessage"), object: self, userInfo: ["message": msg])
            })
        }
    }
    
    func output(_ data: Data) {
        let reportId : CFIndex = 0
        if (data.count > reportSize) {
            log.error("output data too large for USB report")
            return
        }
        if let portal = device {
            log.verbose("=> \(data.toHexString())")
            IOHIDDeviceSetReport(portal, kIOHIDReportTypeOutput, reportId, [UInt8](data), data.count);
        }
    }
    
    func output(_ report: Report) {
        let data = report.serialize()
        output(data)
    }
    
    func outputCommand(_ cmd: Command) {
        output(Report(cmd: cmd))
    }
    
    func connected(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        // It would be better to look up the report size and create a chunk of memory of that size
        let report = UnsafeMutablePointer<UInt8>.allocate(capacity: reportSize)
        device = inIOHIDDeviceRef
        
        let 🙊 : IOHIDReportCallback = { inContext, inResult, inSender, type, reportId, report, reportLength in
            let this : Portal = unsafeBitCast(inContext, to: Portal.self)
            this.input(inResult, inSender: inSender!, type: type, reportId: reportId, report: report, reportLength: reportLength)
        }

        //Hook up inputcallback
        IOHIDDeviceRegisterInputReportCallback(device!, report, reportSize, 🙊, unsafeBitCast(self, to: UnsafeMutableRawPointer.self));

        //Let the world know
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "deviceConnected"), object: self, userInfo: ["class": NSStringFromClass(type(of: self))])
        })
    }

    func removed(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "deviceDisconnected"), object: self, userInfo: ["class": NSStringFromClass(type(of: self))])
        })
    }
    
    func initUsb() {
        let deviceMatch = [kIOHIDProductIDKey: productId, kIOHIDVendorIDKey: vendorId ]
        let managerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        IOHIDManagerSetDeviceMatching(managerRef, deviceMatch as CFDictionary?)
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue);
        IOHIDManagerOpen(managerRef, 0);

        let 🙈 : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this : Portal = unsafeBitCast(inContext, to: Portal.self)
            this.connected(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }

        let 🙉 : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this : Portal = unsafeBitCast(inContext, to: Portal.self)
            this.removed(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        
        IOHIDManagerRegisterDeviceMatchingCallback(managerRef, 🙈, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
        IOHIDManagerRegisterDeviceRemovalCallback(managerRef, 🙉, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
                

        RunLoop.current.run();
    }
}
