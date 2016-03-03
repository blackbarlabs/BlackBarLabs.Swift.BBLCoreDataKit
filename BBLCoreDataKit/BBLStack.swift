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
  static var persistence: BBLPersistence { get }
  
  // Instance
  init()
  var context: NSManagedObjectContext! { get set }
  func performBlock(block: () -> Void)
  func performBlockAndWait(block: () -> Void)
  func save(site: String)
}

// MARK: - Extensions
public extension BBLStack {
  init(concurrencyType: NSManagedObjectContextConcurrencyType) {
    self.init()
    self.context = Self.persistence.addContext(concurrencyType: concurrencyType)
  }
  
  func performBlock(block: () -> Void) { context.performBlock(block) }
  func performBlockAndWait(block: () -> Void) { context.performBlockAndWait(block) }
  func save(site: String) {
    guard self.context.hasChanges else { return }
    do { try context.save() }
    catch let error as NSError { print("===> \(site) save error: \(error.localizedDescription)") }
  }
}

