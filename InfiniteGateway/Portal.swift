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
    
    func input(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {
        let report = Report(data: NSData(bytes: report, length: reportLength))
        if let msg = report.content {
            NSNotificationCenter.defaultCenter().postNotificationName("incomingMessage", object: nil, userInfo: ["message": msg])
        }
    }
    
    func output(report: Report) {
        let reportId : CFIndex = 0
        let data = report.serialize()
        if (data.length > reportSize) {
            print("output data too large for USB report", terminator: "\n")
            return
        }
        if let portal = device {
            //print("Sending output: \(data)")
            IOHIDDeviceSetReport(portal, kIOHIDReportTypeOutput, reportId, UnsafePointer<UInt8>(data.bytes), data.length);
        }
    }
    
    func outputCommand(cmd: Command) {
        output(Report(cmd: cmd))
    }
    
    func connected(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, inIOHIDDeviceRef: IOHIDDevice!) {
        // It would be better to look up the report size and create a chunk of memory of that size
        let report = UnsafeMutablePointer<UInt8>.alloc(reportSize)
        device = inIOHIDDeviceRef
        
        let 🙊 : IOHIDReportCallback = { inContext, inResult, inSender, type, reportId, report, reportLength in
            let this : Portal = unsafeBitCast(inContext, Portal.self)
            this.input(inResult, inSender: inSender, type: type, reportId: reportId, report: report, reportLength: reportLength)
        }

        //Hook up inputcallback
        IOHIDDeviceRegisterInputReportCallback(device, report, reportSize, 🙊, unsafeBitCast(self, UnsafeMutablePointer<Void>.self));

        //Let the world know
        NSNotificationCenter.defaultCenter().postNotificationName("deviceConnected", object: nil, userInfo: ["class": NSStringFromClass(self.dynamicType)])
    }

    func removed(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, inIOHIDDeviceRef: IOHIDDevice!) {
        NSNotificationCenter.defaultCenter().postNotificationName("deviceDisconnected", object: nil, userInfo: ["class": NSStringFromClass(self.dynamicType)])
    }
    
    func initUsb() {
        let deviceMatch = [kIOHIDProductIDKey: productId, kIOHIDVendorIDKey: vendorId ]
        let managerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone)).takeUnretainedValue()

        IOHIDManagerSetDeviceMatching(managerRef, deviceMatch)
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        IOHIDManagerOpen(managerRef, 0);

        let 🙈 : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this : Portal = unsafeBitCast(inContext, Portal.self)
            this.connected(inResult, inSender: inSender, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }

        let 🙉 : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this : Portal = unsafeBitCast(inContext, Portal.self)
            this.removed(inResult, inSender: inSender, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        
        IOHIDManagerRegisterDeviceMatchingCallback(managerRef, 🙈, unsafeBitCast(self, UnsafeMutablePointer<Void>.self))
        IOHIDManagerRegisterDeviceRemovalCallback(managerRef, 🙉, unsafeBitCast(self, UnsafeMutablePointer<Void>.self))
                

        NSRunLoop.currentRunLoop().run();
    }
}