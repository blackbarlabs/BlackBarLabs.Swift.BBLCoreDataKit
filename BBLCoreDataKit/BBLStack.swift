//
//  BBLStack.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Protocols
public protocol BBLStackProto {
    init(concurrencyType: NSManagedObjectContextConcurrencyType)
}

public protocol BBLStack: BBLStackProto {
    typealias T: BBLStackProto
    
    // Static
    static var persistence: BBLPersistence { get set }
    static var uiStack: T? { get set }
    static var modelStack: T? { get set }
    static func stackWithUIContext() -> T
    static func stackWithModelContext() -> T
    
    // Instance
    init()
    var context: NSManagedObjectContext! { get set }
    func performBlock(block: () -> Void)
    func performBlockAndWait(block: () -> Void)
}

// MARK: - Extensions
public extension BBLStack {
    // Static
    static func stackWithUIContext() -> T {
        if uiStack == nil {
            uiStack = T.init(concurrencyType: .MainQueueConcurrencyType)
        }
        return uiStack!
    }
    
    static func stackWithModelContext() -> T {
        if modelStack == nil {
            modelStack = T.init(concurrencyType: .PrivateQueueConcurrencyType)
        }
        return modelStack!
    }
    
    // Instance
    init(concurrencyType: NSManagedObjectContextConcurrencyType) {
        self.init()
        self.context = Self.persistence.addContext(concurrencyType: concurrencyType)
    }
    
    func performBlock(block: () -> Void) { context.performBlock(block) }
    func performBlockAndWait(block: () -> Void) { context.performBlockAndWait(block) }
}


