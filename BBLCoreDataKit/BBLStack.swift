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
public protocol BBLStack {
    // Static
    static var persistence: BBLPersistence { get set }
    static var uiStack: BBLStack? { get set }
    static var modelStack: BBLStack? { get set }
    static func stackWithUIContext() -> BBLStack
    static func stackWithModelContext() -> BBLStack
    
    // Instance
    init()
    var context: NSManagedObjectContext! { get set }
    func performBlock(block: () -> Void)
    func performBlockAndWait(block: () -> Void)
}

// MARK: - Extensions
public extension BBLStack {
    // Static
    static func stackWithUIContext() -> BBLStack {
        if uiStack == nil {
            uiStack = Self.init(concurrencyType: .MainQueueConcurrencyType)
        }
        return uiStack!
    }
    
    static func stackWithModelContext() -> BBLStack {
        if modelStack == nil {
            modelStack = Self.init(concurrencyType: .PrivateQueueConcurrencyType)
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


