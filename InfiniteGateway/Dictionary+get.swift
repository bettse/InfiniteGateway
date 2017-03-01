//
//  Dictionary+get.swift
//  DIMP
//
//  Created by Eric Betts on 6/27/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

//https://gist.github.com/olgakogan/bd6e5eff98aeda63c68c
extension Dictionary {
    
    func get(_ key: Key, defaultValue: Value) -> Value {
        /**
        Returns the value for the given key (if exists), otherwise returns the default value.
        */
        if let value = self[key] {
            return value
        } else {
            return defaultValue
        }
    }
}
