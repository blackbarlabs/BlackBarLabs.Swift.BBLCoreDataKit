//
//  BBLLogging.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 1/15/17.
//  Copyright © 2017 Joel Perry. All rights reserved.
//

import Foundation

public protocol BBLLogging {
    var classDescription: String { get }
    var instanceDescription: String { get }
    
    func logString(_ append: String) -> String
}

public extension BBLLogging {
    var classDescription: String {
        return String(describing: type(of: self))
    }
    
    var instanceDescription: String {
        return String(describing: self)
    }
    
    func logString(_ append: String) -> String {
        return classDescription + "." + append
    }
}
