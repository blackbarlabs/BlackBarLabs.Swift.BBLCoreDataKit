//
//  BBLObject.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Protocols
@objc public protocol BBLObject {
    var idString: String { get set }
}

// MARK: - Extensions
extension NSManagedObject {
    static var entityName : String {
        let components = NSStringFromClass(self).componentsSeparatedByString(".")
        return components[1]
    }
}

public extension BBLObject {
    var identifier: NSUUID {
        get { return NSUUID(UUIDString: idString)! }
        set { idString = newValue.UUIDString }
    }
}
