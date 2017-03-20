//
//  PortalDriver.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/18/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import Cocoa

//Handles initial activation, requestion more token data, notification about new tokens

typealias tokenEvent = (Message.LedPlatform, Int, Token?) -> Void
typealias deviceEvent = (Void) -> Void
typealias responseEvent = (Response) -> Void

class PortalDriver : NSObject {
    static let magic : Data = "(c) Disney 2013".data(using: String.Encoding.ascii)!
    static let secret : Data = Data(bytes: [0xAF, 0x62, 0xD2, 0xEC, 0x04, 0x91, 0x96, 0x8C, 0xC5, 0x2A, 0x1A, 0x71, 0x65, 0xF8, 0x65, 0xFE])
    static let singleton = PortalDriver()
    var portalThread : Thread?
    var portal : Portal = Portal.singleton
    
    var presence : [UInt8:Detail] = [:]
    var encryptedTokens : [UInt8:EncryptedToken] = [:]
    
    var tokenCallbacks : [String:[tokenEvent]] = [:]
    var deviceCallbacks : [String:[deviceEvent]] = [:]
    var responseCallbacks : [String:[responseEvent]] = [:]
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PortalDriver.deviceConnected(_:)), name: NSNotification.Name(rawValue: "deviceConnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PortalDriver.deviceDisconnected(_:)), name: NSNotification.Name(rawValue: "deviceDiscnnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PortalDriver.incomingMessage(_:)), name: NSNotification.Name(rawValue: "incomingMessage"), object: nil)        
        
        self.registerDeviceCallback("connected") { () in
            self.setupResponseCallbacks()
            self.portal.outputCommand(ActivateCommand())
        }
        
        self.registerTokenCallback("loaded") { (platform, nfcIndex, token) in
            self.portal.outputCommand(TagIdCommand(nfcIndex: UInt8(nfcIndex)))
        }
        
        self.registerDeviceCallback("disconnected") { () in
            self.responseCallbacks.removeAll()
        }
        
        portalThread = Thread(target: self.portal, selector:#selector(Portal.initUsb), object: nil)
        if let thread = portalThread {
            thread.start()
        }
    }
    
    func registerTokenCallback(_ event: String, callback: @escaping tokenEvent) {
        tokenCallbacks[event] = tokenCallbacks[event] ?? []
        tokenCallbacks[event]?.append(callback)
    }

    func fireTokenCallbacks(event: String, detail: Detail, token: Token?) {
        DispatchQueue.main.async(execute: {
            for callback in self.tokenCallbacks[event] ?? [] {
                callback(detail.platform, Int(detail.nfcIndex), token)
            }
        })
    }
    
    func registerDeviceCallback(_ event: String, callback: @escaping deviceEvent) {
        deviceCallbacks[event] = deviceCallbacks[event] ?? []
        deviceCallbacks[event]?.append(callback)
    }

    func fireDeviceCallbacks(event: String) {
        DispatchQueue.main.async(execute: {
            for callback in self.deviceCallbacks[event] ?? [] {
                callback()
            }
        })
    }
    
    func registerResponseCallback(_ event: String, callback: @escaping responseEvent) {
        responseCallbacks[event] = responseCallbacks[event] ?? []
        responseCallbacks[event]?.append(callback)
    }

    func fireResponseCallbacks(event: String, response: Response) {
        DispatchQueue.main.async(execute: {
            for callback in self.responseCallbacks[event] ?? [] {
                callback(response)
            }
            
            for callback in self.responseCallbacks["*"] ?? [] {
                callback(response)
            }
        })
    }
    
    func deviceConnected(_ notification: Notification) {
        fireDeviceCallbacks(event: "connected")
    }

    func deviceDisconnected(_ notification: Notification) {
        fireDeviceCallbacks(event: "disconnected")
    }
    
    // Start of "Business logic" //
    
    func setupResponseCallbacks() {
        self.registerResponseCallback("*") { (response) in
            log.debug(response)
        }
        
        self.registerResponseCallback("ActivateResponse") { (response) in
            self.portal.outputCommand(PresenceCommand())
        }
        
        self.registerResponseCallback("PresenceResponse") { (response) in
            self.portal.outputCommand(LightSetCommand(ledPlatform: .all, color: NSColor.black))
            guard let response = response as? PresenceResponse else {
                log.error("Couldn't cast response to expected type")
                return
            }
            for detail in response.details {
                self.presence[detail.nfcIndex] = detail
                self.portal.outputCommand(TagIdCommand(nfcIndex: detail.nfcIndex))
            }
        }
        
        self.registerResponseCallback("TagIdResponse") { (response) in
            guard let response = response as? TagIdResponse else {
                log.error("Couldn't cast response to expected type")
                return
            }
            
            let detail = self.presence[response.nfcIndex]
            self.encryptedTokens[response.nfcIndex] = EncryptedToken(tagId: response.tagId)
            if (detail?.sak == .mifareMini) {
                self.portal.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, sectorNumber: 0, blockNumber: 0))
            }
        }
        
        self.registerResponseCallback("A4Response") { (response) in
            self.portal.outputCommand(ReadCommand(command: response.command as! BlockCommand))
        }
        
        self.registerResponseCallback("StatusResponse") { (response) in
            guard let response = response as? StatusResponse else {
                log.error("Couldn't cast response to expected type")
                return
            }
            if let command = response.command as? A5Command {
                self.portal.outputCommand(A4Command(command: command))
            } else if let command = response.command as? A6Command {
                self.portal.outputCommand(A4Command(command: command))
            } else if let command = response.command as? A7Command {
                self.portal.outputCommand(A4Command(command: command))
            } else if let command = response.command as? B1Command {
                let sectorNumber = command.sectorNumber + 1
                if (Int(sectorNumber) < MifareMini.sectorCount) {
                    self.portal.outputCommand(B1Command(nfcIndex: command.nfcIndex, sectorNumber: sectorNumber))
                }
            } else if let _ = response.command as? C1Command {
                self.portal.outputCommand(C0Command())
            }
        }
        
        self.registerResponseCallback("WriteResponse") { (response) in
            // Read back written block
            self.portal.outputCommand(ReadCommand(command: response.command as! BlockCommand))
        }
        
        self.registerResponseCallback("ReadResponse") { (response) in
            guard let response = response as? ReadResponse else {
                log.error("Couldn't cast response to expected type")
                return
            }

            if (response.status == .success) {
                self.tokenRead(response)
            }
        }
    }
    
    func incomingUpdate(_ update: Update) {
        log.debug(update)
        switch (update.direction) {
        case .arriving:
            let detail = Detail(nfcIndex: update.nfcIndex, platform: update.ledPlatform, sak: update.sak)
            presence[update.nfcIndex] = detail
            fireTokenCallbacks(event: "loaded", detail: detail, token: nil)
        case .departing:
            guard let detail = presence[update.nfcIndex] else {
                log.warning("Could not find record for that nfcIndex")
                return
            }
            fireTokenCallbacks(event: "left", detail: detail, token: nil)
            presence.removeValue(forKey: update.nfcIndex)
        default:
            log.warning("Somehow we have an update that is neither arriving, nor departing")
        }
        
        let tokensOnPlatform = presence.values.filter { (detail) -> Bool in return (detail.platform == update.ledPlatform) }
        
        if (tokensOnPlatform.isEmpty) {
            portal.outputCommand(LightSetCommand(ledPlatform: update.ledPlatform, color: NSColor.black))
        } else if (tokensOnPlatform.count == 1 && update.direction == .arriving) {
            // We must have just added this one
            portal.outputCommand(LightSetCommand(ledPlatform: update.ledPlatform, color: NSColor.white))
        }
    }

    func tokenRead(_ response: ReadResponse) {
        if let token = encryptedTokens[response.nfcIndex] {
            token.load(response.blockNumber, blockData: response.blockData)
            if (token.complete()) {
                let ledPlatform = presence[response.nfcIndex]?.platform ?? .none
                if (token.decryptedToken != nil) {
                    portal.outputCommand(LightSetCommand(ledPlatform: ledPlatform, color: NSColor.green))
                    DispatchQueue.main.async(execute: {
                        for callback in self.tokenCallbacks["complete"] ?? [] {
                            callback(ledPlatform, Int(response.nfcIndex), token.decryptedToken!)
                        }
                    })
                } else {
                    portal.outputCommand(LightSetCommand(ledPlatform: ledPlatform, color: NSColor.red))
                }

                encryptedTokens.removeValue(forKey: response.nfcIndex)
            } else {
                let nextBlock = token.nextBlock()
                portal.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, sectorNumber: 0, blockNumber: nextBlock))
            }
        } //end if token
    }
    
    func incomingMessage(_ notification: Notification) {
        let userInfo = notification.userInfo
        if let message = userInfo?["message"] as? Message {
            if let update = message as? Update {
                incomingUpdate(update)
            } else if let response = message as? Response {
                let responseName = String(describing: type(of: response))
                fireResponseCallbacks(event: responseName, response: response)
            }
        }
    }
}
