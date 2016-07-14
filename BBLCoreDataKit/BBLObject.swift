//
//  BBLObject.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

// MARK: - BBLObject Protocol
@objc public protocol BBLObject {
    var idString: String { get set }
}

// MARK: - Extensions
extension NSManagedObject {
    static var entityName : String {
        let components = NSStringFromClass(self).components(separatedBy: ".")
        return components[1]
    }
}

public extension BBLObject {
    var identifier: UUID {
        get { return UUID(uuidString: idString)! }
        set { idString = newValue.uuidString }
    }
}
