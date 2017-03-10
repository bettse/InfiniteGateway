//
//  NSData+subscript.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 3/9/17.
//  Copyright © 2017 Eric Betts. All rights reserved.
//

import Foundation

public extension Data {
    subscript(origin: Int) -> UInt8 {
        get {
            return ([UInt8](self))[origin]
        }
    }
}
