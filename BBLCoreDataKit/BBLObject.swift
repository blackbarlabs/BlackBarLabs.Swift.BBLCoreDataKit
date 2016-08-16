//
//  BBLObject.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

open class BBLObject: NSManagedObject {
    @NSManaged public var idString: String
    
    open var identifier: UUID {
        get { return UUID(uuidString: idString)! }
        set { idString = newValue.uuidString }
    }
}

// MARK: - Extensions
extension NSManagedObject {
    static var entityName : String {
        let components = NSStringFromClass(self).components(separatedBy: ".")
        return components[1]
    }
}

